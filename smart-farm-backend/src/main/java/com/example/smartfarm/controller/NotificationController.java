package com.example.smartfarm.controller;

import com.example.smartfarm.common.Result;
import com.example.smartfarm.mapper.NotificationMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/notifications")
@CrossOrigin
public class NotificationController {

    @Autowired
    private NotificationMapper notificationMapper;

    // 获取某用户的全部通知
    @GetMapping("/list/{userId}")
    public Result list(@PathVariable Integer userId) {
        return Result.success(notificationMapper.listByUserId(userId));
    }

    // 获取未读数量
    @GetMapping("/unread/{userId}")
    public Result unreadCount(@PathVariable Integer userId) {
        return Result.success(notificationMapper.countUnread(userId));
    }

    // 标记单条已读
    @PostMapping("/read/{id}")
    public Result markRead(@PathVariable Integer id) {
        notificationMapper.markRead(id);
        return Result.success();
    }

    // 全部标记已读
    @PostMapping("/readAll/{userId}")
    public Result markAllRead(@PathVariable Integer userId) {
        notificationMapper.markAllRead(userId);
        return Result.success();
    }
}
