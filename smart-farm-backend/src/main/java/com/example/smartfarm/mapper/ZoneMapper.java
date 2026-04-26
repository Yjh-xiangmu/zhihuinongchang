package com.example.smartfarm.mapper;

import com.example.smartfarm.entity.Zone;
import org.apache.ibatis.annotations.Mapper;
import java.util.List;

@Mapper
public interface ZoneMapper {
    List<Zone> listAll();
    List<Zone> listByManagerId(Integer managerId);
    Zone getById(Integer id);
    int insert(Zone zone);
    int update(Zone zone);
    int deleteById(Integer id);
}
