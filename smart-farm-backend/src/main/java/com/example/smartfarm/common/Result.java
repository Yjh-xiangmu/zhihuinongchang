package com.example.smartfarm.common;

import lombok.Data;

@Data
public class Result {
    private Integer code;
    private String msg;
    private Object data;

    public static Result success(Object data) {
        Result r = new Result();
        r.setCode(200);
        r.setMsg("success");
        r.setData(data);
        return r;
    }

    public static Result success() {
        return success(null);
    }

    public static Result error(String msg) {
        Result r = new Result();
        r.setCode(500);
        r.setMsg(msg);
        return r;
    }
}