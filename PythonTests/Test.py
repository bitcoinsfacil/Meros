#Types.
from typing import Callable, List

#Exceptions.
from PythonTests.Tests.Errors import EmptyError, NodeError, TestError

#Meros classes.
from PythonTests.Meros.Meros import Meros
from PythonTests.Meros.RPC import RPC

#Tests.
from PythonTests.Tests.Merit.ChainAdvancementTest import ChainAdvancementTest
from PythonTests.Tests.Merit.SyncTest import MSyncTest

from PythonTests.Tests.Transactions.DataTest import DataTest
from PythonTests.Tests.Transactions.FiftyTest import FiftyTest

from PythonTests.Tests.Consensus.Verification.UnknownTest import VUnknownTest
from PythonTests.Tests.Consensus.Verification.ParsableTest import VParsableTest
from PythonTests.Tests.Consensus.Verification.CompetingTest import VCompetingTest

from PythonTests.Tests.Consensus.MeritRemoval.SameNonce.CauseTest import MRSNCauseTest
from PythonTests.Tests.Consensus.MeritRemoval.SameNonce.LiveTest import MRSNLiveTest
from PythonTests.Tests.Consensus.MeritRemoval.SameNonce.SyncTest import MRSNSyncTest

from PythonTests.Tests.Consensus.MeritRemoval.VerifyCompeting.CauseTest import MRVCCauseTest
from PythonTests.Tests.Consensus.MeritRemoval.VerifyCompeting.LiveTest import MRVCLiveTest
from PythonTests.Tests.Consensus.MeritRemoval.VerifyCompeting.SyncTest import MRVCSyncTest

from PythonTests.Tests.Consensus.MeritRemoval.Multiple.CauseTest import MRMCauseTest
from PythonTests.Tests.Consensus.MeritRemoval.Multiple.LiveTest import MRMLiveTest

from PythonTests.Tests.Consensus.MeritRemoval.Partial.CauseTest import MRPCauseTest
from PythonTests.Tests.Consensus.MeritRemoval.Partial.LiveTest import MRPLiveTest
from PythonTests.Tests.Consensus.MeritRemoval.Partial.SyncTest import MRPSyncTest

from PythonTests.Tests.Consensus.MeritRemoval.PendingActions.CauseTest import MRPACauseTest
from PythonTests.Tests.Consensus.MeritRemoval.PendingActions.LiveTest import MRPALiveTest

#Arguments.
from sys import argv

#Sleep standard function.
from time import sleep

#SHUtil standard lib.
import shutil

#Format Exception standard function.
from traceback import format_exc

#Initial port.
port: int = 5132

#Results.
ress: List[str] = []

#Tests.
tests: List[Callable[[RPC], None]] = [
    ChainAdvancementTest,
    MSyncTest,

    DataTest,
    FiftyTest,

    VUnknownTest,
    VParsableTest,
    VCompetingTest,

    MRSNCauseTest,
    MRSNLiveTest,
    MRSNSyncTest,

    MRVCCauseTest,
    MRVCLiveTest,
    MRVCSyncTest,

    MRPCauseTest,
    MRPLiveTest,
    MRPSyncTest,

    MRPACauseTest,
    MRPALiveTest,

    MRMCauseTest,
    MRMLiveTest
]

#Tests to run.
#If any were specified over the CLI, only run those.
testsToRun: List[str] = argv[1:]
#Else, run all.
if not testsToRun:
    for test in tests:
        testsToRun.append(test.__name__)

#Remove invalid tests.
for testName in testsToRun:
    found: bool = False
    for test in tests:
        if test.__name__ == testName:
            found = True
            break

    if not found:
        ress.append("\033[0;31mCouldn't find " + testName + ".")
        testsToRun.remove(testName)

#Delete the PythonTests data directory.
try:
    shutil.rmtree("./data/PythonTests")
except FileNotFoundError:
    pass

#Run every test.
for test in tests:
    if not testsToRun:
        break
    if test.__name__ not in testsToRun:
        continue
    testsToRun.remove(test.__name__)

    print("Running " + test.__name__ + ".")

    #Message to display on a Node crash.
    crash: str = "\033[5;31m" + test.__name__ + " caused the node to crash!\033[0;31m"

    #Meros instance.
    meros: Meros = Meros(test.__name__, port, port + 1)
    sleep(2)

    rpc: RPC = RPC(meros)
    try:
        test(rpc)
        ress.append("\033[0;32m" + test.__name__ + " succeeded.")
    except EmptyError as e:
        ress.append("\033[0;33m" + test.__name__ + " is empty.")
        continue
    except NodeError as e:
        ress.append(crash)
    except TestError as e:
        ress.append("\033[0;31m" + test.__name__ + " failed: " + str(e))
        continue
    except Exception as e:
        ress.append("\r\n")
        ress.append("\033[0;31m" + test.__name__ + " is invalid.")
        ress.append(format_exc())
    finally:
        try:
            rpc.quit()
        except NodeError:
            if ress[-1] != crash:
                ress.append(crash)

        print("-" * shutil.get_terminal_size().columns)

for res in ress:
    print(res)
