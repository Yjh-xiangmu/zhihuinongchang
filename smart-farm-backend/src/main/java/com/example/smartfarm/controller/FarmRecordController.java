package com.example.smartfarm.controller;

import com.example.smartfarm.common.Result;
import com.example.smartfarm.entity.FarmRecord;
import com.example.smartfarm.entity.Notification;
import com.example.smartfarm.mapper.FarmRecordMapper;
import com.example.smartfarm.mapper.NotificationMapper;
import com.example.smartfarm.mapper.TaskMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/records")
@CrossOrigin
public class FarmRecordController {

    @Autowired
    private FarmRecordMapper farmRecordMapper;

    @Autowired
    private NotificationMapper notificationMapper;

    @Autowired
    private TaskMapper taskMapper;

    // 员工查看自己提交的记录
    @GetMapping("/list/worker/{workerId}")
    public Result listByWorker(@PathVariable Integer workerId) {
        return Result.success(farmRecordMapper.listByWorkerId(workerId));
    }

    // 负责人查看区域内待审核的记录
    @GetMapping("/list/pending/{zoneId}")
    public Result listPending(@PathVariable Integer zoneId) {
        return Result.success(farmRecordMapper.listPendingByZoneId(zoneId));
    }

    // 负责人查看区域全部记录
    @GetMapping("/list/zone/{zoneId}")
    public Result listByZone(@PathVariable Integer zoneId) {
        return Result.success(farmRecordMapper.listByZoneId(zoneId));
    }

    // 员工提交记录
    @PostMapping("/add")
    public Result add(@RequestBody FarmRecord record) {
        record.setAuditStatus("PENDING");
        farmRecordMapper.insert(record);

        // 如果绑定了任务，把任务状态改为 DONE
        if (record.getTaskId() != null) {
            com.example.smartfarm.entity.Task task = taskMapper.getById(record.getTaskId());
            if (task != null) {
                task.setStatus("DONE");
                taskMapper.update(task);
            }
        }

        return Result.success(record);
    }

    // 负责人审核记录（通过或驳回）
    @PostMapping("/audit")
    public Result audit(@RequestBody Map<String, Object> params) {
        Integer id = (Integer) params.get("id");
        String auditStatus = (String) params.get("auditStatus");  // PASSED 或 REJECTED
        String rejectReason = (String) params.get("rejectReason");

        farmRecordMapper.updateAuditStatus(id, auditStatus, rejectReason);

        // 查询这条记录，给员工发通知
        FarmRecord record = farmRecordMapper.getById(id);
        if (record != null) {
            Notification n = new Notification();
            n.setUserId(record.getWorkerId());
            if ("PASSED".equals(auditStatus)) {
                n.setTitle("记录审核通过");
                n.setContent("您提交的" + record.getRecordType() + "记录已审核通过");
                n.setType("AUDIT_PASS");
            } else {
                n.setTitle("记录被驳回");
                n.setContent("您提交的记录被驳回，原因：" + rejectReason);
                n.setType("AUDIT_REJECT");
            }
            n.setIsRead(0);
            notificationMapper.insert(n);
        }

        return Result.success();
    }
}
