#Types.
from typing import Dict, List, Any

#Meros class.
from python_tests.Meros.Meros import Meros

#JSON standard lib.
import json

#Socket standard lib.
import socket

#RPC class.
class RPC:
    #Constructor.
    def __init__(
        self,
        meros: Meros
    ) -> None:
        self.meros: Meros = meros
        self.socket: socket.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.socket.connect(("127.0.0.1", meros.rpc))

    #Call an RPC method.
    def call(
        self,
        module: str,
        method: str,
        args: List[Any] = []
    ) -> Dict[str, Any]:
        #Send the call.
        self.socket.send(
            bytes(
                json.dumps(
                    {
                        "module": module,
                        "method": method,
                        "args": args
                    }
                ) + "\r\n",
                "utf-8"
            )
        )

        #Get the result.
        response: bytes = self.socket.recv(2)
        while response[-2:] != bytes("\r\n","utf-8"):
            response += self.socket.recv(1)

        #Raise an exception on error.
        result: Dict[str, Any] = json.loads(response)
        if "error" in result:
            raise Exception(result["error"])
        return result

    #Quit Meros.
    def quit(
        self
    ) -> None:
        self.socket.send(
            bytes(
                json.dumps(
                    {
                        "module": "system",
                        "method": "quit",
                        "args": []
                    }
                ) + "\r\n",
                "utf-8"
            )
        )
        self.meros.quit()
