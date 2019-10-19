include "../../Protocol/SHT/Configuration.i.dfy"
include "../../Protocol/LiveSHT/RefinementProof/SHTRefinement.i.dfy"
include "../Common/NodeIdentity.i.dfy"
include "PacketParsing.i.dfy"


module SHT__SHTConcreteConfiguration_i {
import opened SHT__Configuration_i
import opened Common__NodeIdentity_i
import opened SHT__PacketParsing_i
import opened LiveSHT__SHTRefinement_i


datatype SHTConcreteConfiguration = SHTConcreteConfiguration(
    hostIds:seq<EndPoint>,
    rootIdentity:EndPoint,
    params:CParameters)

predicate SHTConcreteConfigurationIsAbstractable(config:SHTConcreteConfiguration)
{
    (forall e :: e in config.hostIds ==> EndPointIsValidIPV4(e))
    && SeqIsUnique(config.hostIds)
    && EndPointIsValidIPV4(config.rootIdentity)
    && CParametersIsValid(config.params)
}

predicate SHTConcreteConfigurationIsValid(config:SHTConcreteConfiguration)
    ensures SHTConcreteConfigurationIsValid(config) ==> SeqIsUnique(config.hostIds);
{
       0 < |config.hostIds| < 0xffff_ffff_ffff_ffff
    && SHTConcreteConfigurationIsAbstractable(config)
    && CParametersIsValid(config.params)
}

function method SHTEndPointIsValid(endPoint:EndPoint, config:SHTConcreteConfiguration) : bool
    requires SHTConcreteConfigurationIsValid(config);
{
    EndPointIsValidIPV4(endPoint)
}


function AbstractifyToConfiguration(config:SHTConcreteConfiguration) : SHTConfiguration
    requires SHTConcreteConfigurationIsAbstractable(config);
{
    SHTConfiguration([], AbstractifyEndPointsToNodeIdentities(config.hostIds), AbstractifyEndPointToNodeIdentity(config.rootIdentity), AbstractifyCParametersToParameters(config.params))
}

predicate ReplicaIndexValid(index:uint64, config:SHTConcreteConfiguration)
{
    0 <= int(index) < |config.hostIds|
}

predicate ReplicaIndicesValid(indices:seq<uint64>, config:SHTConcreteConfiguration)
{
    forall i :: 0 <= i < |indices| ==> ReplicaIndexValid(indices[i], config)
}

lemma lemma_WFSHTConcreteConfiguration(config:SHTConcreteConfiguration)
    ensures SHTConcreteConfigurationIsAbstractable(config)
    && 0 < |config.hostIds|
    && config.rootIdentity in config.hostIds
    ==> SHTConcreteConfigurationIsAbstractable(config)
        && WFSHTConfiguration(AbstractifyToConfiguration(config));
{
    if (SHTConcreteConfigurationIsAbstractable(config)
        && 0 < |config.hostIds|)
    {
        //lemma_CardinalityNonEmpty(config.hostIds);
        var e := config.hostIds[0];
        assert AbstractifyEndPointToNodeIdentity(e) in AbstractifyToConfiguration(config).hostIds;
        assert 0 < |AbstractifyToConfiguration(config).hostIds|;
        var r_hostIds := AbstractifyToConfiguration(config).hostIds;
        forall i, j | 0 <= i < |r_hostIds| && 0 <= j < |r_hostIds|
            ensures r_hostIds[i] == r_hostIds[j] ==> i == j;
        {
            if r_hostIds[i] == r_hostIds[j] {
                if i != j {
                    assert r_hostIds[i] == AbstractifyEndPointToNodeIdentity(config.hostIds[i]);
                    assert r_hostIds[j] == AbstractifyEndPointToNodeIdentity(config.hostIds[j]);
                    lemma_AbstractifyEndPointToNodeIdentity_injective(config.hostIds[i], config.hostIds[j]);
                    assert config.hostIds[i] == config.hostIds[j];
                    reveal_SeqIsUnique();
                    assert i == j;
                    assert false;
                }
            }

        }
    }
}

predicate WFSHTConcreteConfiguration(config:SHTConcreteConfiguration)
    ensures WFSHTConcreteConfiguration(config) ==>
       SHTConcreteConfigurationIsAbstractable(config)
        && WFSHTConfiguration(AbstractifyToConfiguration(config));
{
    lemma_WFSHTConcreteConfiguration(config);
       SHTConcreteConfigurationIsAbstractable(config)
    && 0 < |config.hostIds|
    && config.rootIdentity in config.hostIds
}

method CGetReplicaIndex(replica:EndPoint, config:SHTConcreteConfiguration) returns (found:bool, index:uint64)
    requires SHTConcreteConfigurationIsValid(config);
    requires EndPointIsValidIPV4(replica);
    ensures  found ==> ReplicaIndexValid(index, config) && config.hostIds[index] == replica;
    ensures  found ==> GetHostIndex(AbstractifyEndPointToNodeIdentity(replica), AbstractifyToConfiguration(config)) == int(index);
    ensures !found ==> !(replica in config.hostIds);
    ensures !found ==> !(AbstractifyEndPointToNodeIdentity(replica) in AbstractifyEndPointsToNodeIdentities(config.hostIds));
{
    var i:uint64 := 0;
    lemma_AbstractifyEndPointsToNodeIdentities_properties(config.hostIds);

    while i < uint64(|config.hostIds|)
        invariant i < uint64(|config.hostIds|);
        invariant forall j :: 0 <= j < i ==> config.hostIds[j] != replica;
    {
        if replica == config.hostIds[i] {
            found := true;
            index := i;
    
            ghost var r_replica := AbstractifyEndPointToNodeIdentity(replica);
            ghost var r_replicas := AbstractifyToConfiguration(config).hostIds;
            assert r_replica == r_replicas[index];
            assert ItemAtPositionInSeq(r_replicas, r_replica, int(index));
            calc ==> {
                true;
                    { reveal_SeqIsUnique(); }
                forall j :: 0 <= j < |config.hostIds| && j != int(i) ==> config.hostIds[j] != replica;
            }

            if exists j :: 0 <= j < |r_replicas| && j != int(index) && ItemAtPositionInSeq(r_replicas, r_replica, j) {
                ghost var j :| 0 <= j < |r_replicas| && j != int(index) && ItemAtPositionInSeq(r_replicas, r_replica, j);
                assert r_replicas[j] == r_replica;
                assert AbstractifyEndPointToNodeIdentity(config.hostIds[j]) == r_replica;
                lemma_AbstractifyEndPointToNodeIdentity_injective(config.hostIds[i], config.hostIds[j]);
                assert false;
            }
            assert forall j :: 0 <= j < |r_replicas| && j != int(index) ==> !ItemAtPositionInSeq(r_replicas, r_replica, j);
            assert FindIndexInSeq(r_replicas, r_replica) == int(index);
            return;
        }

        if i == uint64(|config.hostIds|) - 1 {
            found := false;
            return;
        }

        i := i + 1;
    }
    found := false;
}

} 
