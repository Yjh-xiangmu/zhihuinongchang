package com.example.smartfarm.controller;

import com.example.smartfarm.common.Result;
import com.example.smartfarm.entity.AiChatHistory;
import com.example.smartfarm.mapper.AiChatHistoryMapper;
import com.example.smartfarm.mapper.TaskMapper;
import com.example.smartfarm.mapper.AnomalyMapper;
import com.example.smartfarm.mapper.HarvestRecordMapper;
import com.example.smartfarm.mapper.ZoneWorkerMapper;
import com.example.smartfarm.mapper.ZoneMapper;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.*;

@RestController
@RequestMapping("/api/ai")
@CrossOrigin
public class AiController {

    @Value("${qwen.api-key}")
    private String apiKey;

    @Value("${qwen.model:qwen-vl-plus}")
    private String model;

    @Autowired
    private AiChatHistoryMapper aiChatHistoryMapper;

    @Autowired
    private TaskMapper taskMapper;

    @Autowired
    private AnomalyMapper anomalyMapper;

    @Autowired
    private HarvestRecordMapper harvestRecordMapper;

    @Autowired
    private ZoneWorkerMapper zoneWorkerMapper;

    @Autowired
    private ZoneMapper zoneMapper;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    /**
     * 发送消息（支持图片）
     * 请求体: { userId, sessionId, message, imageBase64(可选), role(WORKER/MANAGER/ADMIN) }
     */
    @PostMapping("/chat")
    public Result chat(@RequestBody Map<String, Object> body) {
        Integer userId = (Integer) body.get("userId");
        String sessionId = (String) body.get("sessionId");
        String message = (String) body.get("message");
        String imageBase64 = (String) body.get("imageBase64");
        String userRole = (String) body.getOrDefault("role", "WORKER");

        if (message == null || message.trim().isEmpty()) {
            return Result.error("消息不能为空");
        }

        try {
            // 1. 保存用户消息到历史
            AiChatHistory userMsg = new AiChatHistory();
            userMsg.setUserId(userId);
            userMsg.setSessionId(sessionId);
            userMsg.setRole("user");
            userMsg.setContent(message);
            userMsg.setImageBase64(imageBase64);
            aiChatHistoryMapper.insert(userMsg);

            // 2. 查询历史记录（最近10条，构建上下文）
            List<AiChatHistory> history = aiChatHistoryMapper.listBySession(userId, sessionId);
            int start = Math.max(0, history.size() - 10);
            List<AiChatHistory> recentHistory = history.subList(start, history.size());

            // 3. 构建系统提示词（传入角色和用户ID）
            String systemPrompt = buildSystemPrompt(userRole, userId);

            // 4. 构建 messages 数组
            List<Map<String, Object>> messages = new ArrayList<>();

            // system message
            Map<String, Object> sysMsg = new HashMap<>();
            sysMsg.put("role", "system");
            sysMsg.put("content", systemPrompt);
            messages.add(sysMsg);

            // 历史消息（排除最后一条，最后一条是刚插入的当前消息）
            for (int i = 0; i < recentHistory.size() - 1; i++) {
                AiChatHistory h = recentHistory.get(i);
                Map<String, Object> msg = new HashMap<>();
                msg.put("role", h.getRole());
                msg.put("content", h.getContent() != null ? h.getContent() : "");
                messages.add(msg);
            }

            // 当前用户消息（可能包含图片）
            Map<String, Object> currentMsg = new HashMap<>();
            currentMsg.put("role", "user");

            if (imageBase64 != null && !imageBase64.isEmpty()) {
                // 有图片，用多模态格式
                List<Map<String, Object>> contentList = new ArrayList<>();

                Map<String, Object> imgContent = new HashMap<>();
                imgContent.put("type", "image_url");
                Map<String, String> imgUrl = new HashMap<>();
                // 判断图片类型
                String mimeType = imageBase64.startsWith("/9j/") ? "image/jpeg" : "image/png";
                imgUrl.put("url", "data:" + mimeType + ";base64," + imageBase64);
                imgContent.put("image_url", imgUrl);
                contentList.add(imgContent);

                Map<String, Object> textContent = new HashMap<>();
                textContent.put("type", "text");
                textContent.put("text", message);
                contentList.add(textContent);

                currentMsg.put("content", contentList);
            } else {
                currentMsg.put("content", message);
            }
            messages.add(currentMsg);

            // 5. 调用 Qwen API
            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("model", model);
            requestBody.put("messages", messages);
            requestBody.put("max_tokens", 1500);
            requestBody.put("temperature", 0.7);

            String requestJson = objectMapper.writeValueAsString(requestBody);

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create("https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"))
                    .header("Content-Type", "application/json")
                    .header("Authorization", "Bearer " + apiKey)
                    .POST(HttpRequest.BodyPublishers.ofString(requestJson))
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() != 200) {
                return Result.error("AI服务调用失败: " + response.body());
            }

            // 6. 解析响应
            Map<String, Object> responseMap = objectMapper.readValue(response.body(), Map.class);
            List<Map<String, Object>> choices = (List<Map<String, Object>>) responseMap.get("choices");
            Map<String, Object> assistantMsg = (Map<String, Object>) choices.get(0).get("message");
            String replyContent = (String) assistantMsg.get("content");

            // 7. 保存 AI 回复到历史
            AiChatHistory aiMsg = new AiChatHistory();
            aiMsg.setUserId(userId);
            aiMsg.setSessionId(sessionId);
            aiMsg.setRole("assistant");
            aiMsg.setContent(replyContent);
            aiChatHistoryMapper.insert(aiMsg);

            // 8. 返回
            Map<String, Object> result = new HashMap<>();
            result.put("reply", replyContent);
            result.put("sessionId", sessionId);
            return Result.success(result);

        } catch (Exception e) {
            e.printStackTrace();
            return Result.error("AI服务异常: " + e.getMessage());
        }
    }

    /**
     * 获取某个会话的历史记录
     */
    @GetMapping("/history")
    public Result getHistory(@RequestParam Integer userId,
                             @RequestParam String sessionId) {
        List<AiChatHistory> list = aiChatHistoryMapper.listBySession(userId, sessionId);
        return Result.success(list);
    }

    /**
     * 清除某个会话
     */
    @DeleteMapping("/history")
    public Result clearHistory(@RequestParam Integer userId,
                               @RequestParam String sessionId) {
        aiChatHistoryMapper.deleteSession(userId, sessionId);
        return Result.success();
    }

    /**
     * 根据角色和数据库实际数据生成不同的系统提示词
     */
    private String buildSystemPrompt(String role, Integer userId) {
        // 这是限制AI语气的紧箍咒，去除了所有AI味道
        String styleRule = "【重要要求：请像经验丰富的农业师傅和乡亲面对面聊天一样回答。绝对不要使用任何Markdown排版符号（比如 ###、*、-、--- 等），不要使用加粗。】\n";

        StringBuilder dataContext = new StringBuilder();

        try {
            if ("MANAGER".equals(role)) {
                // 负责人：查地块、作物、具体手下员工（real_name）、员工待办任务数、具体异常
                List<com.example.smartfarm.entity.Zone> myZones = zoneMapper.listByManagerId(userId);
                if (myZones != null && !myZones.isEmpty()) {
                    dataContext.append("【以下是数据库中实时的管辖数据，请以此为依据进行调度和决策：\n");
                    List<Integer> zoneIds = new ArrayList<>();

                    for (com.example.smartfarm.entity.Zone z : myZones) {
                        zoneIds.add(z.getId());
                        dataContext.append("地块：").append(z.getZoneName())
                                .append("（种植：").append(z.getCropName())
                                .append("，生长阶段：").append(z.getGrowthStage()).append("）。");

                        // 查询该区域的员工，并统计各自手里没做完的任务
                        List<com.example.smartfarm.entity.User> workers = zoneWorkerMapper.listWorkersByZone(z.getId());
                        if (workers != null && !workers.isEmpty()) {
                            dataContext.append("本区域可用员工：");
                            for (com.example.smartfarm.entity.User w : workers) {
                                // 查询该员工手里非DONE状态的任务
                                List<com.example.smartfarm.entity.Task> wTasks = taskMapper.listByAssigneeId(w.getId());
                                long wPending = wTasks.stream().filter(t -> !"DONE".equals(t.getStatus())).count();
                                // 这里严谨取了 real_name 而不是 username
                                dataContext.append(w.getRealName()).append("（剩").append(wPending).append("个任务），");
                            }
                        } else {
                            dataContext.append("本区域暂无分配员工，");
                        }
                        dataContext.append("\n");
                    }

                    // 查询具体的未处理异常（非RESOLVED状态），让AI能对症下药
                    List<com.example.smartfarm.entity.Anomaly> anomalies = anomalyMapper.listByZoneIds(zoneIds);
                    boolean hasAnomaly = false;
                    dataContext.append("当前未解决的异常：");
                    for (com.example.smartfarm.entity.Anomaly a : anomalies) {
                        if (!"RESOLVED".equals(a.getStatus())) {
                            hasAnomaly = true;
                            dataContext.append(a.getDescription()).append("；");
                        }
                    }
                    if (!hasAnomaly) {
                        dataContext.append("无。");
                    }
                    dataContext.append("】\n");
                } else {
                    dataContext.append("【当前您的管辖区域暂无数据。】\n");
                }

            } else if ("WORKER".equals(role)) {
                // 员工：查他负责的地块和具体待办任务
                List<Integer> zoneIds = zoneWorkerMapper.listZoneIdsByWorker(userId);
                if (zoneIds != null && !zoneIds.isEmpty()) {
                    dataContext.append("【您的干活数据如下：\n负责区域：");
                    for (Integer zid : zoneIds) {
                        com.example.smartfarm.entity.Zone z = zoneMapper.getById(zid);
                        if (z != null) {
                            dataContext.append(z.getZoneName()).append("（").append(z.getCropName()).append("），");
                        }
                    }
                    dataContext.append("\n");

                    // 查自己的待办任务明细
                    List<com.example.smartfarm.entity.Task> myTasks = taskMapper.listByAssigneeId(userId);
                    dataContext.append("您的待办任务：");
                    boolean hasTask = false;
                    for (com.example.smartfarm.entity.Task t : myTasks) {
                        if (!"DONE".equals(t.getStatus())) {
                            hasTask = true;
                            dataContext.append(t.getTaskName()).append("（").append(t.getDescription()).append("）；");
                        }
                    }
                    if (!hasTask) {
                        dataContext.append("目前没活儿。");
                    }
                    dataContext.append("】\n");
                }

            } else if ("ADMIN".equals(role)) {
                // 管理员：保留全场数据
                List<com.example.smartfarm.entity.Anomaly> allAnomalies = anomalyMapper.listAll();
                long pendingAnomalies = allAnomalies.stream().filter(a -> !"RESOLVED".equals(a.getStatus())).count();

                List<com.example.smartfarm.entity.HarvestRecord> allHarvests = harvestRecordMapper.listAll();
                java.math.BigDecimal totalYield = java.math.BigDecimal.ZERO;
                for (com.example.smartfarm.entity.HarvestRecord r : allHarvests) {
                    if (r.getActualWeight() != null) {
                        totalYield = totalYield.add(r.getActualWeight());
                    }
                }
                dataContext.append("【当前全场全局数据作为参考：全农场未解决异常共 ").append(pendingAnomalies)
                        .append(" 条，历史总产量累计 ").append(totalYield).append(" 公斤。】\n");
            }
        } catch (Exception e) {
            System.err.println("获取AI背景数据失败: " + e.getMessage());
        }

        // 把真实数据结合强业务逻辑喂给AI
        if ("MANAGER".equals(role)) {
            return styleRule + dataContext.toString() +
                    "你是一名资深的农业生产主管，指导区域负责人管理田间。现在你已经拿到了数据库里实时的地块信息、手下的员工名单（真实姓名）、每个员工现在手里积压的任务数量，以及当前没解决的异常病害。\n" +
                    "当负责人问你如何调度或安排工作时，你必须根据上面的真实数据来回答，绝不能瞎编。\n" +
                    "核心调度逻辑：优先把紧急的异常病害指派给手里任务最少的员工去处理；如果有人活儿太多，建议找同区域的其他闲置员工分担。\n" +
                    "回答一定要说出具体的员工名字、具体的地块名字，让人觉得你真的是在根据农场现状做调度，注重落地执行。";

        } else if ("ADMIN".equals(role)) {
            return styleRule + dataContext.toString() +
                    "你是一位现代农场经营管理专家，协助农场管理员进行全局战略统筹。结合提供的总产量和未处理异常总数，提供宏观决策支持。\n" +
                    "指出可能拖累产量的短板，并提供长效的管理优化建议，以提升农场整体经济效益为核心。";

        } else {
            return styleRule + dataContext.toString() +
                    "你是一个经验丰富的老农业技术员，给一线员工提供实操指导。结合上面的员工自己的待办任务和负责区域，指导他该怎么干活。遇到病虫害直接给具体的用药和操作步骤，注重实干。";
        }
    }
}