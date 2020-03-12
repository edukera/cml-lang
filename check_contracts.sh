#! /bin/bash

RET_CONTRACTS="\
auction.arl \
auction_lazy.arl \
auction_no_memory.arl \
c3n.arl \
certification_token.arl \
certificate_generator.arl \
clause_io_acceptance_of_delivery.arl \
coase.arl \
competition.arl \
empty.arl \
escrow_penalty.arl \
escrow_without_spec.arl \
erc20.arl \
guarantee_fund.arl \
hello.arl \
miles.arl \
miles_with_expiration_simple.arl \
mini_dao.arl \
mwe_medium.arl \
perishable.arl \
register_vote.arl \
register_candidate.arl \
sig_challenge.arl \
zero_coupon_bond.arl \
zero_coupon_bond_with_insurance.arl \
"

REMAINED_RET_CONTRACTS="
animal_tracking.arl \
auction_zilliqa.arl \
autocallable.arl \
bond.arl \
c3n_without_loop.arl \
erc721.arl \
escrow_basic.arl \
escrow_simple.arl \
fizzy.arl \
health_care.arl \
ico.arl \
miles_with_expiration.arl \
vehicle_lifecycle.arl \
voting_process.arl \
"

EXEC_CONTRACTS="\
auction.arl \
auction_lazy.arl \
auction_no_memory.arl \
c3n.arl \
certificate_generator.arl \
certification_token.arl \
clause_io_acceptance_of_delivery.arl \
coase.arl \
competition.arl \
empty.arl \
erc20.arl \
escrow_penalty.arl \
escrow_without_spec.arl \
guarantee_fund.arl \
hello.arl \
miles.arl \
miles_with_expiration_simple.arl \
mini_dao.arl \
mwe_medium.arl \
perishable.arl \
register_candidate.arl \
register_vote.arl \
sig_challenge.arl \
zero_coupon_bond.arl \
zero_coupon_bond_with_insurance.arl \
"

REMAINED_EXEC_CONTRACTS="\
animal_tracking.arl \
auction_zilliqa.arl \
autocallable.arl \
bond.arl \
c3n_without_loop.arl \
erc721.arl \
escrow_basic.arl \
escrow_simple.arl \
fizzy.arl \
health_care.arl \
ico.arl \
miles_with_expiration.arl \
vehicle_lifecycle.arl \
voting_process.arl \
"

VERIF_CONTRACTS="\
auction.arl \
auction_lazy.arl \
auction_no_memory.arl \
c3n.arl \
certificate_generator.arl \
certification_token.arl \
clause_io_acceptance_of_delivery.arl \
coase.arl \
competition.arl \
empty.arl \
erc20.arl \
escrow_penalty.arl \
escrow_without_spec.arl \
guarantee_fund.arl \
hello.arl \
miles.arl \
miles_with_expiration_simple.arl \
mini_dao.arl \
mwe_medium.arl \
perishable.arl \
register_candidate.arl \
register_vote.arl \
sig_challenge.arl \
zero_coupon_bond.arl \
zero_coupon_bond_with_insurance.arl \
"

REMAINED_VERIF_CONTRACTS="\
animal_tracking.arl \
auction_zilliqa.arl \
autocallable.arl \
bond.arl \
c3n_without_loop.arl \
erc721.arl \
escrow_basic.arl \
escrow_simple.arl \
fizzy.arl \
health_care.arl \
ico.arl \
miles_with_expiration.arl \
vehicle_lifecycle.arl \
voting_process.arl \
"

RET=0

echo "Check return"
echo ""
echo "                                                             AST RET"
for i in $RET_CONTRACTS; do
    ./check_ret.sh ./contracts/$i
    if [ $? -ne 0 ]; then
        RET=1
    fi
done

echo ""
echo "(not pass)                                                   AST RET"
for i in $REMAINED_RET_CONTRACTS; do
    ./check_ret.sh ./contracts/$i
done

echo ""
echo ""
echo "Check exec"

echo ""
echo "                                                             RET LP  LG  LS"
for i in $EXEC_CONTRACTS; do
    ./check_exec.sh ./contracts/$i
    if [ $? -ne 0 ]; then
        RET=1
    fi
done

echo ""
echo "(not pass)                                                   RET LP  LG  LS"
for i in $REMAINED_EXEC_CONTRACTS; do
    ./check_exec.sh ./contracts/$i
done

echo ""
echo ""
echo "Check verif"

echo ""
echo "                                                             RET OUT PROVE"
for i in $VERIF_CONTRACTS; do
    ./check_verif.sh ./contracts/$i
    if [ $? -ne 0 ]; then
        RET=1
    fi
done
echo ""
echo "(not pass)                                                   RET OUT PROVE"
for i in $REMAINED_VERIF_CONTRACTS; do
    ./check_verif.sh ./contracts/$i
done

exit $RET
