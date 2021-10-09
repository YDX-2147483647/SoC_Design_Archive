# GPZDA

提取[GPZDA](https://docs.novatel.com/OEM7/Content/Logs/GPZDA.htm)格式的GPS信息。

```
$GPZDA,hhmmss.ss,dd,mm,yyyy,,*hh
```

> 注释里的“轮”指clock。

## `GpsReceiver`

```mermaid
stateDiagram-v2
    [*] --> Prefix
    note right of Prefix: 匹配"$GPZDA,"；<br>任何时候不匹配都回到它。
    
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
    Output --> Prefix
```

## `Comparer`

这是异步的，匹配完成后的下一clock才有反馈。

```mermaid
stateDiagram-v2
    [*] --> Pending
    
    Pending --> Pending
    Pending --> Reject : 中道崩殂
    Pending --> Resolve : full match
    
    Reject --> Pending
    Reject --> Reject : 中道崩殂
    Resolve --> Pending
    Resolve --> Resolve : full match
```

### `ComparerSync`

类似`Comparer`，但匹配完成的那一个clock就会反馈。

不是FSM，要不然做不到即时。
