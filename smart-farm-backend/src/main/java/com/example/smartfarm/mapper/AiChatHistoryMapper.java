package com.example.smartfarm.mapper;

import com.example.smartfarm.entity.AiChatHistory;
import org.apache.ibatis.annotations.*;
import java.util.List;

@Mapper
public interface AiChatHistoryMapper {

    @Insert("INSERT INTO ai_chat_history(user_id, session_id, role, content, image_base64) " +
            "VALUES(#{userId}, #{sessionId}, #{role}, #{content}, #{imageBase64})")
    @Options(useGeneratedKeys = true, keyProperty = "id")
    int insert(AiChatHistory history);

    @Select("SELECT id, user_id, session_id, role, content, create_time " +
            "FROM ai_chat_history WHERE user_id = #{userId} AND session_id = #{sessionId} " +
            "ORDER BY create_time ASC")
    List<AiChatHistory> listBySession(@Param("userId") Integer userId,
                                      @Param("sessionId") String sessionId);

    @Select("SELECT DISTINCT session_id, MAX(create_time) as create_time " +
            "FROM ai_chat_history WHERE user_id = #{userId} " +
            "GROUP BY session_id ORDER BY create_time DESC LIMIT 10")
    List<AiChatHistory> listRecentSessions(Integer userId);

    @Delete("DELETE FROM ai_chat_history WHERE user_id = #{userId} AND session_id = #{sessionId}")
    int deleteSession(@Param("userId") Integer userId, @Param("sessionId") String sessionId);
}