#Errors lib.
import ../../../lib/Errors

#DB object.
import objects/DBObj
export DBObj

#DB libs.
import TransactionsDB
import ConsensusDB
import MeritDB

proc commit*(
    db: DB,
    height: int
) {.forceCheck: [].} =
    TransactionsDB.commit(db)
    ConsensusDB.commit(db)
    MeritDB.commit(db, height)
