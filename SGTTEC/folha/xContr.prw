#INCLUDE "Protheus.ch"
#INCLUDE "TOPCONN.CH"
USER FUNCTION XNEGOC()

LOCAL nValor:= 0

	if cEmpAnt = "02"
		IF SRA->RA_MENSIND = '1' .and. SRA->RA_SINDICA = '02'
		
			IF ANOMES(SRA->RA_ADMISSA) = RCH->RCH_PER .OR. SUBS(RCH->RCH_PER,5,2) = '02'
				nValor 	 := SRA->RA_SALARIO * 0.03
				fGeraVerba("540",nValor,0,,,,,,,,.T.,)
			ENDIF

		ELSEIF SRA->RA_SINDICA = '02'

			IF ANOMES(SRA->RA_ADMISSA) = RCH->RCH_PER .OR. SUBS(RCH->RCH_PER,5,2) $ '02|03' .OR. ANOMES(MONTHSUM(SRA->RA_ADMISSA,1)) = RCH->RCH_PER
				nValor 	 := SRA->RA_SALARIO * 0.03
				fGeraVerba("540",nValor,0,,,,,,,,.T.,)
			ENDIF

		ENDIF
	endif
	
RETURN


