package com.example.smartfarm.mapper;

import com.example.smartfarm.entity.Anomaly;
import org.apache.ibatis.annotations.Mapper;
import java.util.List;

@Mapper
public interface AnomalyMapper {
    List<Anomaly> listAll();
    List<Anomaly> listByZoneId(Integer zoneId);
    List<Anomaly> listByZoneIds(List<Integer> zoneIds);
    List<Anomaly> listByReporterId(Integer reporterId);
    Anomaly getById(Integer id);
    int insert(Anomaly anomaly);
    int update(Anomaly anomaly);
}
