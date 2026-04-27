package com.example.smartfarm.controller;

import com.example.smartfarm.common.Result;
import com.example.smartfarm.entity.Notification;
import com.example.smartfarm.entity.Task;
import com.example.smartfarm.mapper.NotificationMapper;
import com.example.smartfarm.mapper.TaskMapper;
import com.example.smartfarm.mapper.ZoneWorkerMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/tasks")
@CrossOrigin
public class TaskController {

    @Autowired
    private TaskMapper taskMapper;

    @Autowired
    private NotificationMapper notificationMapper;

    @Autowired
    private ZoneWorkerMapper zoneWorkerMapper;

    // 员工查看自己的任务
    @GetMapping("/list/worker/{workerId}")
    public Result listByWorker(@PathVariable Integer workerId) {
        return Result.success(taskMapper.listByAssigneeId(workerId));
    }

    // 负责人查看某区域任务
    @GetMapping("/list/zone/{zoneId}")
    public Result listByZone(@PathVariable Integer zoneId) {
        return Result.success(taskMapper.listByZoneId(zoneId));
    }

    // 派发任务（同时发通知给员工）
    @PostMapping("/add")
    public Result add(@RequestBody Task task) {
        task.setStatus("PENDING");
        taskMapper.insert(task);
        if (task.getAssigneeId() != null) {
            Notification n = new Notification();
            n.setUserId(task.getAssigneeId());
            n.setTitle("收到新任务");
            n.setContent("您有新任务：" + task.getTaskName() + "，请及时处理");
            n.setType("TASK_NEW");
            n.setIsRead(0);
            notificationMapper.insert(n);
        }
        return Result.success(task);
    }

    // 更新任务状态
    @PutMapping("/update")
    public Result update(@RequestBody Task task) {
        taskMapper.update(task);
        return Result.success();
    }

    // 删除任务
    @DeleteMapping("/delete/{id}")
    public Result delete(@PathVariable Integer id) {
        taskMapper.deleteById(id);
        return Result.success();
    }
}