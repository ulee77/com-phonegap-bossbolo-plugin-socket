package com.phonegap.bossbolo.plugin.socket;

public interface Consumer<T> {
    void accept(T t);
}