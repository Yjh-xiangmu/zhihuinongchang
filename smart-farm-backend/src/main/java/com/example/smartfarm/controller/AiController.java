package com.example.smartfarm.controller;

import com.example.smartfarm.common.Result;
import com.example.smartfarm.entity.AiChatHistory;
import com.example.smartfarm.mapper.AiChatHistoryMapper;
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

            // 3. 构建系统提示词（根据角色不同）
            String systemPrompt = buildSystemPrompt(userRole);

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
                // 判断图片类型（默认jpeg）
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
     * 根据角色生成不同的系统提示词
     */
    private String buildSystemPrompt(String role) {
        switch (role) {
            case "WORKER":
                return "你是一个专业的农业助手，专门帮助农场一线员工解决问题。" +
                        "你的职责包括：1) 识别植物病虫害（用户可能上传图片）并给出防治建议；" +
                        "2) 解答日常农事操作问题，如施肥、浇水、修剪的具体方法；" +
                        "3) 帮助判断作物生长状态是否正常。" +
                        "回答要简洁实用，避免专业术语堆砌，用员工能听懂的语言。" +
                        "如果用户上传了植物照片，请仔细分析图片中的病害特征、虫害痕迹或生长异常，给出诊断和处理建议。";

            case "MANAGER":
                return "你是一个农业生产管理顾问，帮助区域负责人做出更好的管理决策。" +
                        "你的职责包括：1) 分析作物各生长阶段的管理要点和注意事项；" +
                        "2) 根据描述的生长情况判断是否存在风险，给出预警建议；" +
                        "3) 帮助制定合理的施肥、灌溉计划；" +
                        "4) 解答病虫害防治的综合管理方案。" +
                        "回答要有数据支撑，适当给出具体的用量、时间节点等量化建议。";

            case "ADMIN":
                return "你是一个农场经营管理顾问，帮助农场管理员做战略决策。" +
                        "你的职责包括：1) 提供种植规划建议，包括轮作、间作等种植制度；" +
                        "2) 分析产量影响因素，给出提升产量和品质的建议；" +
                        "3) 帮助进行成本效益分析；" +
                        "4) 提供市场行情分析和销售建议；" +
                        "5) 解答农场整体运营管理问题。" +
                        "回答要站在全局角度，注重经济效益和可持续发展。";

            default:
                return "你是一个专业的农业助手，请回答用户关于农业生产的问题。";
        }
    }
}