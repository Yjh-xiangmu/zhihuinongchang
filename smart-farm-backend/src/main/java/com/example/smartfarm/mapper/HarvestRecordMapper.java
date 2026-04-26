package com.example.smartfarm.mapper;

import com.example.smartfarm.entity.HarvestRecord;
import org.apache.ibatis.annotations.Mapper;
import java.util.List;

@Mapper
public interface HarvestRecordMapper {
    List<HarvestRecord> listAll();
    List<HarvestRecord> listByZoneId(Integer zoneId);
    List<HarvestRecord> listByWorkerId(Integer workerId);
    HarvestRecord getById(Integer id);
    int insert(HarvestRecord record);
}
