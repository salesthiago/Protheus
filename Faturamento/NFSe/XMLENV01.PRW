user function XMLENV01()
			aProd		:= PARAMIXB[1]
			cMensCli	:= PARAMIXB[2]
			cMensFis	:= PARAMIXB[3]
			aDest 		:= PARAMIXB[4]
			aNota 		:= PARAMIXB[5]
			aDupl		:= PARAMIXB[6]  
			aDeduz		:= PARAMIXB[7]
			aTotal		:= PARAMIXB[8]
			aISSQN		:= PARAMIXB[9]
			aAIDF		:= PARAMIXB[10]
			aInterm	    := PARAMIXB[11]
			aRetido 	:= PARAMIXB[12]				
			aDeducao	:= PARAMIXB[13]
			aConstr	    := PARAMIXB[14]
            
			//cMensFis += chr(13)+chr(10)+"MATERIAL E EQUIPAMENTOS 85% R$ 139.199,90"+chr(13)+chr(10)
			//cMensFis += "MAO DE OBRA 15% R$ 24.564.69"+chr(13)+chr(10)
			//cMensFis += "ISSQN 5% SOBRE NF R$ 8.188,22"
            //aprod[1][34] := "381140000"
			            
			aParam      := {aProd,cMensCli,cMensFis,aDest,aNota,aDupl,aDeduz,aTotal,aISSQN,aAIDF,aInterm,aRetido,aDeducao,aConstr}
return(aParam)
