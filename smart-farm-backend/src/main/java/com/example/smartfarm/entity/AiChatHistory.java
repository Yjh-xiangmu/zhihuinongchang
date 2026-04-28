package com.example.smartfarm.entity;

import lombok.Data;
import java.util.Date;

@Data
public class AiChatHistory {
    private Integer id;
    private Integer userId;
    private String sessionId;
    private String role;        // user 或 assistant
    private String content;
    private String imageBase64;
    private Date createTime;
}