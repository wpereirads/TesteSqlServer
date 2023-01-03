USE [DW_VEN]
GO
/****** Object:  StoredProcedure [dbo].[atualizar_fato_pedido]    Script Date: 03/01/2023 15:42:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--EXEC ATUALIZAR_FATO_PEDIDO 

ALTER   proc [dbo].[atualizar_fato_pedido]
as

/******	Proc alteradado por William Peraira em 09/08/2022	******/
--Adicionado os campos de usuários, data e hora de liberação dos pedidos

/******	Proc alteradado por William Peraira em 11/08/2022	******/
--Adicionado o campo de numero de nota fiscal.

/******	Proc alteradado por Luiz Fernando em 12/08/2022	******/
--Acrescentar zeros a esquerda na coluna Nota Fiscal

	--truncate table fato_pedido

	begin
	
	delete from fato_pedido
	where dataEmissao BETWEEN DATEADD(DAY, - 35, GETDATE()) AND GETDATE()
	
	end
	begin
	with tb_aux as (

(SELECT * 
	FROM  (SELECT 
			ped.DB_PED_NRO numeroPedido
			,msg.DB_Msg_Data dataHora
			,isnull(msg.DB_Msg_Texto, '') mensagemPedido
			,isnull(right(replicate('0',9)+cast(np.DB_NOTAP_NRO as varchar(9)) ,9 ) +'-'+ np.DB_NOTAP_SERIE,'') numeroNf
			,DupRank = ROW_NUMBER() OVER (
		       PARTITION BY ped.DB_PED_NRO
		       ORDER BY (msg.DB_Msg_Data) desc, 
							(right(replicate('0',9)+cast(np.DB_NOTAP_NRO as varchar(9)) ,9 ) +'-'+ np.DB_NOTAP_SERIE) )
				FROM [172.19.113.21].MercanetPrd.dbo.db_pedido ped 
	
	left join [172.19.113.21].MercanetPrd.dbo.DB_MENSAGEM msg on msg.DB_Msg_Pedido = ped.DB_PED_NRO
	left join [172.19.113.21].MercanetPrd.dbo.DB_NOTA_PROD np on np.DB_NOTAP_PED_ORIG = ped.DB_PED_NRO ) AS T
		
		WHERE DupRank = 1 --and numeroPedido = 159695
		)
)

	insert into fato_pedido (	
					[numeroPedido]
					,[codigoCliente]
					,[ordemCompra]
					,[pedidoOriginal]
					,[dataEmissao]
					,[nomeTransportador]
					,[codigoRepresentante]
					,[situacao]
					,[condicaoPagamento]
					,[centro]
					,[nomeFilial]
					,[codigoProduto]
					,[quantidadeSolicitada]
					,[quantidadeAtendida]
					,[quantidadeAberto]
					,[quantidadeCancelada]
					,[valorAberto]
					,[valorTotal]
					,[valorFalta]
					,[valorFaturado]
					,[canal]
					,[segmentacao]
					,[usuarioDigitador]
					,[nomeDigitador]
					,[mes]
					,[operacao]
					,[tipoPedido]
					,[dataRecebido]
					,[horaRecebido]
					,[dataEnvioSAP]
					,[horaEnvioSAP]
					,[motivoBloqueio]
					,[usuariosLiberacao]
					,[alcada]
					,[pendencia]
					,[codigoPolitica]
					,[politica]
					,[descricaoPolitica]
					,[codigoFormaPagamento]
					,[DescricaoFormaPagamento]
					,[motivoCancelamento]
					,[usuarioCancelamento]
					,[descontoAplicadoItem]
					,[pedidoRascunho]
					,[tipoItem]
					,[valorLiquido]
					,[usuarioPrimeiraLib]
					,[usuarioSegundaLib]
					,[usuarioTerceiraLib]
					,[usuarioQuartaLib]
					,[usuarioQuintaLib]
					,[dataPrimeiraLib]
					,[dataSegundaLib]
					,[dataTerceiraLib]
					,[dataQuartaLib]
					,[dataQuintaLib]
					,[horaPrimeiraLib]
					,[horaSegundaLib]
					,[horaTerceiraLib]
					,[horaQuartaLib]
					,[horaQuintaLib]
					--,[numeroNotaFiscal]
					,[situacaoCorporativo]
					,[descCapa]	
					,[descCapa2]
					,[precoBrutoUnitario]
					,mensagemPedido
					,dataMensagem
					,horaMensagem
					,numeroNotaFiscal
					,tipoPedidoCabecalho
					
				)
	

	select distinct
		 [numeroPedido]				=	ped.DB_PED_NRO
		,codigoCliente				=	ped.DB_PED_CLIENTE
		,ordemCompra				=	ped.DB_PED_ORD_COMPRA 
		,pedidoOriginal				=	ped.DB_PED_NRO_ORIG
		,dataEmissao				=	ped.DB_PED_DT_EMISSAO
		,nomeTransportador			=	trans.DB_TBTRA_NOME		
		,codigoRepresentante		=	ped.DB_PED_REPRES		
		,situacao					=	CASE ped.DB_PED_SITUACAO 
											WHEN 0 THEN 'Aberto' 
											WHEN 1 THEN 'Bloqueado'	
											WHEN 2 THEN 'Faturado Parcial' 
											WHEN 3 THEN 'Saldo'  
											When 4 THEN 'Faturado'  
											WHEN 9 then 'Cancelado' 
											ELSE '' 
										END
		,condicaoPagamento			=	pgto.db_tbpgto_descr
		,centro						=	ped.DB_Ped_Empresa
		,nomeFilial					=	emp.DB_TBEMP_NOME
		,codigoProduto				=	prod.DB_PEDI_PRODUTO 
		,quantidadeSolicitada		=	(prod.DB_PEDI_QTDE_SOLIC)
		,quantidadeAtendida			=	(prod.DB_PEDI_QTDE_ATEND)
		,quantidadeAberto			=	(prod.DB_PEDI_QTDE_SOLIC) - (prod.DB_PEDI_QTDE_ATEND)
		,quantidadeCancelada		=	(prod.DB_PEDI_QTDE_CANC)
		,valorAberto				=	round(((prod.db_pedi_qtde_solic - isnull(prod.DB_PEDI_QTDE_ATEND, 0)) *  prod.db_pedi_preco_liq),2)
		,valorTotal					=	round(((prod.db_pedi_qtde_solic - isnull(prod.db_pedi_qtde_canc	, 0)) *  prod.db_pedi_preco_liq),2)
		,valorFalta					=	round(((prod.db_pedi_qtde_solic - isnull(prod.DB_PEDI_QTDE_ATEND, 0)) *  prod.db_pedi_preco_liq),2)
		,valorFaturado				=	round(((prod.DB_PEDI_QTDE_ATEND - isnull(prod.db_pedi_qtde_canc	, 0)) *  prod.db_pedi_preco_liq),2)
		,canal						=	ramo.DB_TBATV_DESCRICAO
		,segmentacao				=	atu.DB_AREA_DESCR
		,usuarioDigitador			=	compl.DB_PEDC_USU_CRIA	
		,nomeDigitador				=	usu.NOME
		,Mes						=	case substring(CONVERT(VARCHAR, DB_PED_DT_EMISSAO,102),6,2) 
											WHEN 01 THEN '01 - Janeiro'
											WHEN 02 THEN '02 - Fevereiro' 
											WHEN 03 THEN '03 - Março'
											WHEN 04 THEN '04 - Abril'
											WHEN 05 THEN '05 - Maio'
											WHEN 06 THEN '06 - Junho'
											WHEN 07 THEN '07 - Julho'
											WHEN 08 THEN '08 - Agosto'
											WHEN 09 THEN '09 - Setembro'
											WHEN 10 THEN '10 - Outubro'
											WHEN 11 THEN '11 - Novembro'
											WHEN 12 THEN '12 - Dezembro'
											ELSE '' 
										END		
		,operacao					=   ped.DB_PED_OPERACAO		--Campo adicionado
		,tipoPedido					=	case ped.DB_PED_OPERACAO
											when 'ORB'  then 'Venda'
											when 'ZKEB' then 'Venda'
											when 'OPL3' then 'Venda'
											when 'KEB'  then 'Venda'
											when 'KBB'  then 'Consignado'
											when 'ZKBB' then 'Consignado'
											when 'YDOA' then 'Bonificação' -- Campo adicionado 04/08
										else 'Outros' end
		,[dataRecebido]				=	ped.DB_PED_DATA_RECEB	--Campo adicionado DATA
		,[horaRecebido]				=	ped.DB_PED_DATA_RECEB	--Campo adicionado HORA
		,[dataEnvioSAP]				=	ped.DB_PED_DATA_ENVIO	--Campo adicionado DATA
		,[horaEnvioSAP]				=	ped.DB_PED_DATA_ENVIO	--Campo adicionado HORA
		,motivoBloqueio				=	ped.DB_PED_MOTIVO_BLOQ  --Campo Adicionado
		,usuariosLiberacao			=	ped.DB_PED_LIB_USUS --Campo Adicionado
		,alcada						=	CASE peda.DB_PEDAL_ALCADA --Campo Adicionado
											WHEN 1	THEN  'Comercial'
											WHEN 10   THEN 'Distribuidores' 
											WHEN 14 THEN 'Crédito' 
											WHEN 13 THEN 'Crédito'
											WHEN 12 THEN 'Comercial'
											WHEN 11 THEN 'Comercial'
											WHEN 15 THEN 'Crédio'
											WHEN 16 THEN 'Comercial'
											WHEN 2  THEN 'Comercial'
											WHEN 20 THEN 'Comercial'
											WHEN 3  THEN 'Comercial'
											WHEN 4  THEN 'Comercial'
											WHEN 5  THEN 'Comercial'
											WHEN 6  THEN 'Comercial'
											WHEN 7  THEN 'Comercial'
											WHEN 8  THEN 'Comercial'
											WHEN 9  THEN 'Comercial' 		
										END
		,pendencia					= case when compl.DB_PEDC_AVALIADO = 1 and ped.db_ped_situacao = 1 then 'SIM' else '' end -- campo adicionado
		,codigoPolitica				=	d.DB_PEDD_CODPOL			--Campo adicionado
		,politica					=	p.DESCRICAO					--Campo adicionado
		,desccricaoPolitica			=	d.DB_PEDD_DCTOPOL			--Campo adicionado
		,codigoFormaPagamento		=	compl.DB_PEDC_FORMA_PGTO	--campo adicionado
		,descricaoFormaPagamento	=	f.DB_FOPG_DESCR				--campo adicionado
		,motivoCancelamento			=	c.DB_TBMCA_DESCR			--campo adicionado
		,usuarioCancelamento		=	prod.db_pedi_usu_canc		--campo adicionado
		,descontoAplicadoItem		=	prod.DB_PEDI_DESCTOP		--Campo adicionado		
		,pedidoRascunho				=	Case compl.DB_PEDC_RASCUNHO 
											when 1 then 'RASCUNHO'
											when 0 then 'EFETIVADO'
											else ''
										END
		,tipoItem					=	case prod.DB_PEDI_TIPO
											when 'V' then 'Venda'
											when 'B' then 'Bonificação'
											when 'N' then 'Ret. Simbolico Integração'
											else 'Outros'
										end -- Campo adicionado em 26/07/2022
		,valorLiquido		= prod.DB_PEDI_PRECO_LIQ -- Campo adicionado em 26/07/2022
		,usuarioPrimeiraLib = dbo.[SEPARATEXTOPEDIDOCRM](replace(replace(replace(replace(replace(isnull(ped.DB_PED_LIB_USUS,''),'!1',''),'!2',''),'!3',''),'!4',''),'!5',''), 1, ';') -- Campo adicionado em 09/08/2022   
		,usuarioSegundaLib	= dbo.[SEPARATEXTOPEDIDOCRM](replace(replace(replace(replace(replace(isnull(ped.DB_PED_LIB_USUS,''),'!1',''),'!2',''),'!3',''),'!4',''),'!5',''), 2, ';') -- Campo adicionado em 09/08/2022    
		,usuarioTerceiraLib	= dbo.[SEPARATEXTOPEDIDOCRM](replace(replace(replace(replace(replace(isnull(ped.DB_PED_LIB_USUS,''),'!1',''),'!2',''),'!3',''),'!4',''),'!5',''), 3, ';') -- Campo adicionado em 09/08/2022    
		,usuarioQuartaLib	= dbo.[SEPARATEXTOPEDIDOCRM](replace(replace(replace(replace(replace(isnull(ped.DB_PED_LIB_USUS,''),'!1',''),'!2',''),'!3',''),'!4',''),'!5',''), 4, ';') -- Campo adicionado em 09/08/2022    
		,usuarioQuintaLib	= dbo.[SEPARATEXTOPEDIDOCRM](replace(replace(replace(replace(replace(isnull(ped.DB_PED_LIB_USUS,''),'!1',''),'!2',''),'!3',''),'!4',''),'!5',''), 5, ';') -- Campo adicionado em 09/08/2022    
		,dataPrimeiraLib	= dbo.[SEPARATEXTOPEDIDOCRM]((isnull(ped.DB_PED_LIB_DATAS,'')), 1, ';') -- Campo adicionado em 09/08/2022  	 
		,dataSegundaLib		= dbo.[SEPARATEXTOPEDIDOCRM]((isnull(ped.DB_PED_LIB_DATAS,'')), 2, ';') -- Campo adicionado em 09/08/2022  	 
		,dataTerceiraLib	= dbo.[SEPARATEXTOPEDIDOCRM]((isnull(ped.DB_PED_LIB_DATAS,'')), 3, ';') -- Campo adicionado em 09/08/2022  	 
		,dataQuartaLib		= dbo.[SEPARATEXTOPEDIDOCRM]((isnull(ped.DB_PED_LIB_DATAS,'')), 4, ';') -- Campo adicionado em 09/08/2022  	 
		,dataQuintaLib		= dbo.[SEPARATEXTOPEDIDOCRM]((isnull(ped.DB_PED_LIB_DATAS,'')), 5, ';') -- Campo adicionado em 09/08/2022  	 
		,horaPrimeiraLib	= dbo.[SEPARATEXTOPEDIDOCRM]((isnull(compl.DB_PEDC_LIB_HORAS,'')), 1, ';') -- Campo adicionado em 09/08/2022  
		,horaSegundaLib		= dbo.[SEPARATEXTOPEDIDOCRM]((isnull(compl.DB_PEDC_LIB_HORAS,'')), 2, ';')	-- Campo adicionado em 09/08/2022  
		,horaTerceiraLib	= dbo.[SEPARATEXTOPEDIDOCRM]((isnull(compl.DB_PEDC_LIB_HORAS,'')), 3, ';')	-- Campo adicionado em 09/08/2022  
		,horaQuartaLib		= dbo.[SEPARATEXTOPEDIDOCRM]((isnull(compl.DB_PEDC_LIB_HORAS,'')), 4, ';')	-- Campo adicionado em 09/08/2022  
		,horaQuintaLib		= dbo.[SEPARATEXTOPEDIDOCRM]((isnull(compl.DB_PEDC_LIB_HORAS,'')), 5, ';')	-- Campo adicionado em 09/08/2022  
		--,[numeroNotaFiscal]	=	isnull(concat (nota.DB_NOTA_NRO, '-', nota.DB_NOTA_SERIE),'') 
		--,[numeroNotaFiscal] = right(replicate('0',9)+cast(nfp.DB_NOTAP_NRO as varchar(9)) ,9 ) +'-'+ nfp.DB_NOTAP_SERIE
		,[situacaoCorporativo]	= case PED.dB_PED_SITCORP
										when NULL then 'Outros'
										when 100 then 'Enviado para SAP'
										when 200 then 'Aguardando conf. Token'
										when 222 then 'Token Expirado'
										when 999 then 'Pedido rejeitado'
										else  ''
									end
		,[descCapa]			=	DB_PED_DESCTO
		,[descCapa]			=	DB_PED_DESCTO2
		,precoBrutoUnitario	=	DB_PEDI_PRECO_UNIT
		,mensagemPedido		=	aux.mensagemPedido
		,dataMensagem		=	aux.dataHora
		,horaMensagem		=	aux.dataHora
		,numeroNotaFiscal	=	aux.numeroNf
		,tipoPedidoCabecalho	=	case ped.DB_Ped_Tipo
										 WHEN 'AC'  THEN 'ABERTURA CONSIGNAÇÃO'
										 WHEN 'AG'  THEN 'ABERTURA DE GRADE'
										 WHEN 'CA'  THEN 'PEDIDO DE CAMPANHA'
										 WHEN 'CF'  THEN 'CONSIGNAÇÃO FECHADA'
										 WHEN 'COM' THEN 'COMPLEMENTO DE GRADE'
										 WHEN 'DQ'  THEN 'PEDIDO DE PFCQ'
										 WHEN 'EP'  THEN 'EXCEÇÃO PORTAL KA'
										 WHEN 'FI'  THEN 'VENDA FINANCIADA'
										 WHEN 'PB'  THEN 'PEDIDO DE BONIFICAÇÃO'
										 WHEN 'PV'  THEN 'PEDIDO DE VENDA'
										 WHEN 'PVT' THEN 'TROCA BA E ES'
										 WHEN 'RG'  THEN 'REPOSIÇÃO DE GRADE'
										 ELSE '' 
									END
		--,mensagemPedido		=	(select top 1 isnull(msg.DB_Msg_Texto, '')
		--								from [172.19.113.21].MercanetPrd.dbo.DB_MENSAGEM msg 
		--									where msg.DB_Msg_Pedido = ped.DB_PED_NRO 
		--									order by msg.DB_Msg_Texto desc)
		--,dataMensagem		= (select top 1 isnull(msg.DB_Msg_Data, '')
		--								from [172.19.113.21].MercanetPrd.dbo.DB_MENSAGEM msg 
		--									where msg.DB_Msg_Pedido = ped.DB_PED_NRO 
		--									order by msg.DB_Msg_Texto desc) 
		--
		--,horaMensagem		= (select top 1 isnull(msg.DB_Msg_Data, '')
		--								from [172.19.113.21].MercanetPrd.dbo.DB_MENSAGEM msg 
		--									where msg.DB_Msg_Pedido = ped.DB_PED_NRO 
		--									order by msg.DB_Msg_Texto desc)
		

		--,[numeroNotaFiscal] =  (select top 1 right(replicate('0',9)+cast(nfp.DB_NOTAP_NRO as varchar(9)) ,9 ) +'-'+ nfp.DB_NOTAP_SERIE
		--							from [172.19.113.21].MercanetPrd.dbo.DB_NOTA_PROD nfp 
		--								where nfp.DB_NOTAP_PED_ORIG = ped.DB_PED_NRO
		--									order by nfp.DB_NOTAP_NRO)
		
		
	from 		[172.19.113.21].MercanetPrd.dbo.DB_PEDIDO ped

	inner join  [172.19.113.21].MercanetPrd.dbo.DB_PEDIDO_COMPL compl	
				on compl.DB_PEDC_NRO = ped.DB_PED_NRO
	left join 	[172.19.113.21].MercanetPrd.dbo.DB_PEDIDO_PROD prod		
				on prod.DB_PEDI_PEDIDO = ped.DB_PED_NRO
	inner join 	[172.19.113.21].MercanetPrd.dbo.DB_CLIENTE cli
				on cli.DB_CLI_CODIGO = ped.DB_PED_CLIENTE
	inner join 	[172.19.113.21].MercanetPrd.dbo.DB_CLIENTE_COMPL comp   
				on comp.DB_CLIC_COD=cli.DB_CLI_CODIGO 
				and comp.DB_CLIC_COD=ped.DB_PED_CLIENTE
	left join 	[172.19.113.21].MercanetPrd.dbo.DB_AREA_ATUACAO atu
				on atu.DB_AREA_CODIGO = comp.DB_CLIC_AREAATU
	left  join 	[172.19.113.21].MercanetPrd.dbo.DB_NOTA_FISCAL nota		
				on nota.DB_NOTA_PED_ORIG=ped.DB_PED_NRO --and nota.DB_NOTA_CLIENTE = ped.DB_PED_CLIENTE
	left join 	[172.19.113.21].MercanetPrd.dbo.DB_TB_TRANSP trans  
				on DB_TBTRA_COD = ped.DB_PED_COD_TRANSP
	inner join 	[172.19.113.21].MercanetPrd.dbo.db_tb_cpgto pgto		
				on pgto.DB_TBPGTO_COD = ped.DB_PED_COND_PGTO
	left join 	[172.19.113.21].MercanetPrd.dbo.DB_TB_EMPRESA emp		
				on emp.DB_TBEMP_CODIGO = ped.DB_Ped_Empresa
	left join 	[172.19.113.21].MercanetPrd.dbo.DB_TB_RAMO_ATIV ramo	
				on ramo.DB_TBATV_CODIGO = cli.DB_CLI_RAMATIV
	left  join	[172.19.113.21].MercanetPrd.dbo.DB_USUARIO usu			
				on usu.USUARIO = compl.DB_PEDC_USU_CRIA
	left join	[172.19.113.21].MercanetPrd.dbo.db_pedido_alcada peda 													--Join adicionado
				on peda.db_pedal_pedido = ped.db_ped_nro and peda.db_pedal_status = 0	--Join adicionado
	left join	[172.19.113.21].MercanetPrd.dbo.db_pedido_desconto d														--Join adicionado
				on d.DB_PEDD_NRO = ped.DB_PED_NRO and d.DB_PEDD_SEQIT = prod.DB_PEDI_SEQUENCIA and 	d.DB_PEDD_TPPOL = 'P' 	--Join adicionado
	left join	[172.19.113.21].MercanetPrd.dbo.db_polcom_principal p 													--Join adicionado
				on p.POLITICA = d.db_pedd_codpol   										--Join adicionado
	left join	[172.19.113.21].MercanetPrd.dbo.DB_TB_FORMA_PGTO f										 				--Join adicionado
				on f.DB_FOPG_CODIGO = compl.DB_PEDC_FORMA_PGTO  				 		--Join adicionado
	left join	[172.19.113.21].MercanetPrd.dbo.DB_TB_MOTCANC c															--Join adicionado
				on c.DB_TBMCA_CODIGO =
				prod.DB_PEDI_MOTCANC								--Join adicionado
	--left join [172.19.113.21].MercanetPrd.dbo.DB_NOTA_PROD nfp
	--			on nfp.DB_NOTAP_PED_ORIG = ped.DB_PED_NRO and nfp.DB_NOTAP_PRODUTO = prod.db_pedi_produto
	left join [172.19.113.21].MercanetPrd.dbo.DB_MENSAGEM msg
				on msg.DB_Msg_Pedido = ped.DB_PED_NRO 
	left join tb_aux aux 
				on aux.numeroPedido = ped.DB_PED_NRO

	where	(DB_PED_DT_EMISSAO BETWEEN DATEADD(DAY, - 35, GETDATE()) AND GETDATE())	and 
			cli.DB_CLI_CODIGO <> DB_CLI_CGCMF
			and db_pedi_produto is not null --and db_ped_nro = 159695 
	
			
	GROUP 	BY 
			 DB_PED_NRO
			,DB_PED_CLIENTE
			,DB_PED_ORD_COMPRA
			,DB_PED_NRO_ORIG
			,DB_PED_DT_EMISSAO
			,DB_TBTRA_NOME
			,DB_PED_REPRES
			,DB_PED_SITUACAO
			,prod.DB_PEDI_PRODUTO
			,DB_CLI_CIDADE
			,DB_CLI_ESTADO
			,Db_CliC_Usu_Cria
			,db_cli_codigo 
			,DB_CLIC_RAMATIVII
			,db_tbpgto_descr
			,ped.DB_Ped_Empresa
			,DB_TBEMP_NOME
			,DB_PED_COND_PGTO
			,DB_AREA_DESCR
			,DB_TBATV_DESCRICAO
			,DB_PEDC_USU_CRIA
			,NOME
			,DB_PED_OPERACAO		-- Campos adicionados no group by
			,DB_PED_DATA_ENVIO		-- Campos adicionados no group by
			,DB_PED_DATA_RECEB		-- Campos adicionados no group by
			,DB_PEDC_AVALIADO		-- Campos adicionados no group by
			,DB_PEDAL_ALCADA		-- Campos adicionados no group by
			,DB_PEDD_CODPOL			-- Campos adicionados no group by
			,DESCRICAO				-- Campos adicionados no group by
			,DB_PEDI_QTDE_SOLIC		-- Campos adicionados no group by
			,DB_PEDI_QTDE_ATEND		-- Campos adicionados no group by
			,DB_PEDI_QTDE_SOLIC		-- Campos adicionados no group by
			,DB_PEDI_QTDE_CANC		-- Campos adicionados no group by
			,db_pedi_preco_liq		-- Campos adicionados no group by
			,DB_PEDC_FORMA_PGTO		-- Campos adicionados no group by
			,DB_FOPG_DESCR			-- Campos adicionados no group by
			,DB_PEDD_TPPOL			-- Campos adicionados no group by
			,DB_PEDD_DCTOPOL		-- Campos adicionados no group by
			,DB_PEDI_DESCTOP		-- Campos adicionados no group by
			,DB_PED_MOTIVO_BLOQ		-- Campos adicionados no group by
			,DB_PED_LIB_USUS		-- Campos adicionados no group by
			,db_pedi_motcanc		-- Campos adicionados no group by
			,DB_PEDI_USU_CANC		-- Campos adicionados no group by
			,DB_TBMCA_DESCR			-- Campos adicionados no group by
			,compl.DB_PEDC_RASCUNHO 
			,prod.DB_PEDI_TIPO		-- Campos adicionados no group by
			,prod.DB_PEDI_PRECO_LIQ	-- Campos adicionados no group by
			,ped.DB_PED_LIB_DATAS   -- Campos adicionados no group by
			,ped.DB_PED_LIB_USUS	-- Campos adicionados no group by
			,COMPL.DB_PEDC_LIB_HORAS-- Campos adicionados no group by
			--,nfp.DB_NOTAP_NRO
			--,nfp.DB_NOTAP_SERIE
			,DB_PED_SITCORP
			,DB_PED_DESCTO
			,DB_PED_DESCTO2
			,DB_PEDI_PRECO_UNIT
			--,msg.DB_Msg_Texto
			--,msg.DB_Msg_Data
			--,msg.DB_Msg_Data
			,aux.mensagemPedido		
			,aux.dataHora	
			,aux.numeroNf
			,ped.DB_Ped_Tipo

		end

		begin

			update tb_log_atualizacaoFatoPedido set timestamp = GETDATE()

		end