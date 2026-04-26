package com.example.smartfarm.entity;

import lombok.Data;
import java.util.Date;

@Data
public class Anomaly {
    private Integer id;
    private Integer zoneId;
    private String zoneName;
    private Integer reporterId;
    private String reporterName;
    private String anomalyType;
    private String description;
    private String images;
    private String status;
    private Integer handlerId;
    private String handleNote;
    private Date createTime;
    private Date updateTime;
}
