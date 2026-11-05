User Function FA050DEL()

    If SE2->E2_PREFIXO == "SP "
        SZ2->(DbSetOrder(1))
        If SZ2->(DbSeek(xFilial("SZ2")+SE2->E2_NUM))
            RecLock("SZ2",.F.)
                SZ2->Z2_APROVA := ""
            SZ2->(MsUnlock())
        Endif
    EndIf

Return .T.
