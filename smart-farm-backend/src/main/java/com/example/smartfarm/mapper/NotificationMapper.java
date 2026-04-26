package com.example.smartfarm.mapper;

import com.example.smartfarm.entity.Notification;
import org.apache.ibatis.annotations.Mapper;
import java.util.List;

@Mapper
public interface NotificationMapper {
    List<Notification> listByUserId(Integer userId);
    int insert(Notification notification);
    int markRead(Integer id);
    int markAllRead(Integer userId);
    int countUnread(Integer userId);
}
