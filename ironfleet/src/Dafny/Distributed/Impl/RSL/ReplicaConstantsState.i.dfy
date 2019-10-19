include "ConstantsState.i.dfy"
include "PaxosWorldState.i.dfy" // For those that still depend on it; should be deprecated away.

module LiveRSL__ReplicaConstantsState_i {
import opened LiveRSL__ConstantsState_i
import opened LiveRSL__PaxosWorldState_i 

datatype ReplicaConstantsState = ReplicaConstantsState(
    my_index:uint64,
    all:ConstantsState)

predicate ReplicaConstantsStateIsAbstractable(rc:ReplicaConstantsState)
{
       ConstantsStateIsAbstractable(rc.all)
    && ReplicaIndexValid(rc.my_index, rc.all.config)
}

function AbstractifyReplicaConstantsStateToLReplicaConstants(rc:ReplicaConstantsState) : LReplicaConstants
    requires ReplicaConstantsStateIsAbstractable(rc);
{
    LReplicaConstants(int(rc.my_index), AbstractifyConstantsStateToLConstants(rc.all))
}

predicate ReplicaConstantsState_IsValid(rcs:ReplicaConstantsState)
{
       ConstantsStateIsValid(rcs.all)
    && ReplicaConstantsStateIsAbstractable(rcs)
}

method InitReplicaConstantsState(endPoint:EndPoint, config:CPaxosConfiguration) returns (rc:ReplicaConstantsState)
    requires CPaxosConfigurationIsValid(config);
    requires PaxosEndPointIsValid(endPoint, config);
    requires endPoint in config.replica_ids; // To satisfy WFReplicaConstantsState
    ensures ReplicaConstantsState_IsValid(rc);
    ensures rc.all.config.replica_ids[rc.my_index] == endPoint;
    ensures rc.all.config == config;
    ensures rc.all.params.max_integer_val > rc.all.params.max_log_length > 0;
    ensures rc.all.params.max_log_length < 10000;
    ensures rc.all.params == StaticParams();
{
    var params := StaticParams(); 
    //var config := CPaxosConfiguration(world.config.replica_ids);
    var constants := ConstantsState(config, params);
    var found, index := CGetReplicaIndex(endPoint, config);
    rc := ReplicaConstantsState(index, constants);
}


} 
