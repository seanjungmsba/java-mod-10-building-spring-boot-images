package com.example.restservice.models;

import org.springframework.data.cassandra.core.mapping.PrimaryKey;
import org.springframework.data.cassandra.core.mapping.Table;

@Table
public class Counter {
    @PrimaryKey
    private String name;

    private Long count;

    public Counter() {
    }

    public Counter(Long count, String name) {
        this.count = count;
        this.name = name;
    }

    public Long incrementAndGet() {
        this.count += 1;
        return count;
    }
}
