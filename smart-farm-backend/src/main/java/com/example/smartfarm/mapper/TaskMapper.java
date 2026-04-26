package com.example.smartfarm.mapper;

import com.example.smartfarm.entity.Task;
import org.apache.ibatis.annotations.Mapper;
import java.util.List;

@Mapper
public interface TaskMapper {
    List<Task> listByZoneId(Integer zoneId);
    List<Task> listByAssigneeId(Integer assigneeId);
    List<Task> listByZoneIds(List<Integer> zoneIds);
    Task getById(Integer id);
    int insert(Task task);
    int update(Task task);
    int deleteById(Integer id);
    int countByZoneIdAndStatus(Integer zoneId, String status);
}
