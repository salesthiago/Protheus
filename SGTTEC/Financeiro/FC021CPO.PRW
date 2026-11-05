/*
Ponto de entrada localizado na rotina de consulta do fluxo de caixa
o problema é que os títulos em desdobramento não estão entrando no fluxo
assim será alterado o parâmetro neste ponto de entrada e 
restaurando o seu conteúdo no FC021ATRB

*/

User Function FC021CPO()

//Local aCposAna := aClone(PARAMIXB)
Local aRet := {}

PUTMV("MV_NRASDSD",".T.")

Return(aRet)
