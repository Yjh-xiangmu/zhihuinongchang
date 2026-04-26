package com.example.smartfarm.entity;

import lombok.Data;
import java.util.Date;

@Data
public class Notification {
    private Integer id;
    private Integer userId;
    private String title;
    private String content;
    private String type;
    private Integer isRead;
    private Date createTime;
}
