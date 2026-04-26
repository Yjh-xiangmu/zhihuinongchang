package com.example.smartfarm.entity;

import lombok.Data;
import java.math.BigDecimal;
import java.util.Date;

@Data
public class Zone {
    private Integer id;
    private String zoneName;
    private String cropName;
    private Integer managerId;
    private String managerName;
    private String status;
    private Date plantDate;
    private BigDecimal area;
    private BigDecimal targetYield;
    private String zoneType;
    private String growthStage;
    private Date createTime;
}
