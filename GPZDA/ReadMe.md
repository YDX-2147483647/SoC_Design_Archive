# GPZDA

提取[GPZDA](https://docs.novatel.com/OEM7/Content/Logs/GPZDA.htm)格式的GPS信息。

```
$GPZDA,hhmmss.ss,dd,mm,yyyy,,*hh
```

## `GpsReceiver`

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Prefix
    note right of Prefix: 匹配"$GPZDA,"
    Prefix --> Idle: 不匹配
    
    Prefix --> Split
    state Split {
        [*] --> Num
        Num --> Num
        Num --> Comma
        Comma --> Num
        Comma --> Comma

        Num --> Star
        Comma --> Star
        Star --> [*]
    }
    Split --> Check
    Check --> Output
    Output --> Idle
```

## `Comparer`

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Pending
    
    Pending --> Pending
    Pending --> Reject : 中道崩殂
    Pending --> Resolve : full match
    
    Reject --> Idle
    Resolve --> Idle
```

