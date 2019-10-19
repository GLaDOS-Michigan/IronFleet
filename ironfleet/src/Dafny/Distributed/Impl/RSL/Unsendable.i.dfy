include "../../Protocol/RSL/Replica.i.dfy"
include "PacketParsing.i.dfy"

module LiveRSL__Unsendable_i {
    import opened LiveRSL__Replica_i
    import opened LiveRSL__PacketParsing_i

    predicate IosReflectIgnoringUnsendable(ios:seq<LIoOp<EndPoint, seq<byte>>>)
    {
           |ios| == 1
        && ios[0].LIoOpReceive?
        && (   !Demarshallable(ios[0].r.msg, CMessage_grammar())
            || !Marshallable(parse_Message(DemarshallFunc(ios[0].r.msg, CMessage_grammar()))))
    }
    
    predicate HostNextIgnoreUnsendable(s:LScheduler, s':LScheduler, ios:seq<LIoOp<EndPoint, seq<byte>>>)
    {
           s.nextActionIndex == 0
        && s' == s.(nextActionIndex := 1)
        && IosReflectIgnoringUnsendable(ios)
    }
}
