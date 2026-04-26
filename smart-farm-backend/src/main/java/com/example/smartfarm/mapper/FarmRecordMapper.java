package com.example.smartfarm.mapper;

import com.example.smartfarm.entity.FarmRecord;
import org.apache.ibatis.annotations.Mapper;
import java.util.List;

@Mapper
public interface FarmRecordMapper {
    List<FarmRecord> listByZoneId(Integer zoneId);
    List<FarmRecord> listByZoneIds(List<Integer> zoneIds);
    List<FarmRecord> listPendingByZoneId(Integer zoneId);
    List<FarmRecord> listByWorkerId(Integer workerId);
    List<FarmRecord> listByZoneIdAndTaskId(Integer zoneId, Integer taskId);
    FarmRecord getById(Integer id);
    int insert(FarmRecord record);
    int updateAuditStatus(Integer id, String auditStatus, String rejectReason);
}
