/**
 * Created by frankvanloon on 4/16/24.
 */
public with sharing class FS_WorkOrderPricingAction {

	public with sharing class PricingRequest {
		@InvocableVariable(Required=true)
		public Id workOrderId;
	}

	public with sharing class PricingResult {
		@InvocableVariable
		public String currencyCode;
		@InvocableVariable
		public List<WorkOrderLineItem> lines;
		@InvocableVariable
		public String errorMessage;
	}
    
    public with sharing class PricingException extends Exception {}

	private static Set<String> PRICEABLE_LINE_TYPES = new Set<String> { 'Parts', 'Labor', 'Travel' };
	private static Set<String> PRICEABLE_LINE_STATUSES = new Set<String> { 'Open', 'Priced' };

	@InvocableMethod(Label='Calculate WorkOrder Pricing')
	public static List<PricingResult> calculatePricing(List<PricingRequest> requests) {
		List<PricingResult> results = new List<PricingResult>();

		Set<String> lineTypes = PRICEABLE_LINE_TYPES;
		Set<String> lineStatuses = PRICEABLE_LINE_STATUSES;

		// Get Platform Event JSON and ReplayId
		for (PricingRequest request : requests) {
			PricingResult result = new PricingResult();
			result.lines = new List<WorkOrderLineItem>();

			// Get WO & Price-able Lines (LineType, LineStatus, Qty)
			WorkOrder wo = [SELECT  Id, WorkOrderNumber, CurrencyIsoCode, Status, Order_Type__c,
				ContractEntitlement__c, SAP_ActivityType__c, SoldTo__r.fxCustomerNumber_Target__c,
				ShipTo__r.fxCustomerNumber_Target__c, Payer__r.fxCustomerNumber_Target__c,
				Asset.SalesOrg__c, LocationId, Location.SalesOrg__c,
				(SELECT Id, LineItemNumber, Line_Type__c, Quantity__c, Unit_Price__c, Part__c, Part_Number__c,
					ContractPercentDiscount__c, UnitOfMeasure__c, Status,
					Use_Product_Sales_UOM__c, UOM_Code__c, CurrencyIsoCode, Discount_Type__c
					FROM WorkOrderLineItems
					WHERE Line_Type__c IN :lineTypes AND Status IN :lineStatuses)
				FROM WorkOrder
				WHERE Id = :request.workOrderId];

			// Invoke GetPrice Service
			if (wo != null && wo.WorkOrderLineItems != null && !wo.WorkOrderLineItems.isEmpty()) {
				result.errorMessage = invokeGetPriceService(wo, wo.WorkOrderLineItems);
				result.currencyCode = wo.CurrencyIsoCode;
				applyContractDiscounts(wo, wo.WorkOrderLineItems);
				result.lines.addAll(wo.WorkOrderLineItems);
			} else {
				result.errorMessage = 'No Work Order Lines found to Price';
			}

			results.add(result);
		}

		return results;
	}

	/*
	 *  Invoke the BOOMI "Get Price" Web Service
	 *  The resulting price is populated into the WorkOrderLineItem UnitPrice.
	 */
	public static String invokeGetPriceService(WorkOrder wo, List<WorkOrderLineItem> lines)
	{
		String salesOrg = wo.Location.SalesOrg__c;
		Set<Id> productIds = new Set<Id>();
		Map<String, WorkOrderLineItem> lineMap = new Map<String, WorkOrderLineItem>();
		for (WorkOrderLineItem line : lines)
		{
			if (line.Part__c == null && line.Quantity__c > 0) {
				continue;
			}
			productIds.add(line.Part__c);
			lineMap.put(line.LineItemNumber, line);
		}

		// SVMXINT-465 - Handle No-Lines Error
		if (lineMap.size() == 0)
		{
			return 'No Work Order Lines are ready to price. Please ensure both Part and Qty have been entered.';
		}

		Map<Id, Product2> productMap = new Map<Id, Product2>(
		[SELECT Id, Name, Part_Number__c, QuantityUnitOfMeasure, Unit_of_Measure_Code__c,
			(SELECT Id, External_ID__c, Sales_Org__c, Sales_Unit__c, Sales_Unit_Code__c
				FROM Product_Sales__r WHERE Sales_Org__c = :salesOrg)
			FROM Product2 WHERE Id IN :productIds]);

		XmlStreamWriter w = new XmlStreamWriter();
		w.writeStartDocument(null, '1.0');
		w.writeStartElement(null, 'Order', null);
		w.writeStartElement(null, 'Header', null);
		w.writeStartElement(null, 'SalesOrg', null);
		if (salesOrg == null) {
			return 'Cannot price a Work Order without a valid SalesOrg. Please correct and retry.';
		}
		w.writeCharacters(salesOrg);
		w.writeEndElement(); // SalesOrg

		if (wo.SAP_ActivityType__c != null)
		{
			w.writeStartElement(null, 'OrderType', null);
			w.writeCharacters(wo.SAP_ActivityType__c);
			w.writeEndElement(); // OrderType
		}
		w.writeStartElement(null, 'PartnerSystemOrderNo', null);
		w.writeCharacters(wo.WorkOrderNumber);
		w.writeEndElement(); // PartnerSystemOrderNo
		w.writeStartElement(null, 'Partners', null);
		w.writeStartElement(null, 'Partner', null);
		w.writeStartElement(null, 'PartnerType', null);
		w.writeCharacters('SoldTo');
		w.writeEndElement(); // PartnerType
		w.writeStartElement(null, 'PartnerNumber', null);
		String soldToNumber = wo.SoldTo__r.fxCustomerNumber_Target__c;
		if (soldToNumber == null) {
			return 'Cannot price a Work Order without a valid Sold-To Account. Please correct and retry.';
		}
		w.writeCharacters(soldToNumber);
		w.writeEndElement(); // PartnerNumber
		w.writeEndElement(); // Partner
		w.writeStartElement(null, 'Partner', null);
		w.writeStartElement(null, 'PartnerType', null);
		w.writeCharacters('ShipTo');
		w.writeEndElement(); // PartnerType
		w.writeStartElement(null, 'PartnerNumber', null);
		String shipToId = (wo.ShipTo__r == null || wo.ShipTo__r.fxCustomerNumber_Target__c == null)
				? null : wo.ShipTo__r.fxCustomerNumber_Target__c;
		if (shipToId == null) {
			return 'Cannot price a Work Order without a valid Ship-To Account. Please correct and retry.';
		}
		w.writeCharacters(shipToId);
		w.writeEndElement(); // PartnerNumber
		w.writeEndElement(); // Partner
		w.writeStartElement(null, 'Partner', null);
		w.writeStartElement(null, 'PartnerType', null);
		w.writeCharacters('Payer');
		w.writeEndElement(); // PartnerType
		w.writeStartElement(null, 'PartnerNumber', null);
		String payerId = (wo.Payer__r == null || wo.Payer__r.fxCustomerNumber_Target__c == null)
				? null : wo.Payer__r.fxCustomerNumber_Target__c;
		if (payerId == null) {
			return 'Cannot price a Work Order without a valid Payer Account. Please correct and retry.';
		}
		w.writeCharacters(payerId);
		w.writeEndElement(); // PartnerNumber
		w.writeEndElement(); // Partner
		w.writeEndElement(); // Partners
		w.writeEndElement(); // Header
		w.writeStartElement(null, 'Detail', null);
		Integer lineCount = 0;
		for (String lineName : lineMap.keySet())
		{
			WorkOrderLineItem line = lineMap.get(lineName);
			Product2 prod = productMap.get(line.Part__c);
			line.Part_Number__c = prod.Part_Number__c;
			lineCount++;
			w.writeStartElement(null, 'LineItem', null);
			w.writeStartElement(null, 'Direction', null);
			w.writeCharacters('In');
			w.writeEndElement(); // Direction(In)

			w.writeStartElement(null, 'PartnerLineNumber', null);
			w.writeCharacters(lineName);
			w.writeEndElement(); // PartnerLineNumber
			w.writeStartElement(null, 'Material', null);
			w.writeCharacters(prod.Part_Number__c + '');
			w.writeEndElement(); // Material
			w.writeStartElement(null, 'Quantity', null);
			w.writeCharacters(line.Quantity__c + '');
			w.writeEndElement(); // Quantity
			if (line.Use_Product_Sales_UOM__c == true)
			{
				FS_WorkDetailManager.updateUnitOfMeasureCodes(line, salesOrg, prod);
				w.writeStartElement(null, 'UnitOfMeasure', null);
				w.writeCharacters(line.UOM_Code__c + '');
				w.writeEndElement(); // UnitOfMeasure
			}
			w.writeEndElement(); // LineItem
		}
		w.writeStartElement(null, 'Summary', null);
		w.writeStartElement(null, 'TotalNoLines', null);
		w.writeCharacters(lineCount + '');
		w.writeEndElement(); // TotalNoLines
		w.writeEndElement(); // Summary
		w.writeEndElement(); // Detail
		w.writeEndElement(); // Order

		String xmlRQ = w.getXmlString();
		w.close();

		// Use Named Credential based on Sandbox/Prod Custom Setting...
		C_SET_9999_ORG_SETTINGS__c settings = C_SET_9999_ORG_SETTINGS__c.getInstance();
		String namedCred = (settings.isSBX__c) ? 'Boomi_SBX' : 'Boomi_PROD';
		//String boomi_auth = 'boomi_auth=U0ZEQ0BwZXJraW5lbG1lci1TMUxCNlk6YTgzNWE1ZjItMTdlNS00NDU4LWI1ODEtZjAxMWJiYjA1NGZm';
		String url = 'callout:' + namedCred + '/ws/rest/SFS/Query/GetPrice';// + ';' + boomi_auth;
		System.debug('~ GET_PRICE_URL = ' + url);

		HttpRequest req = new HttpRequest();
		req.setMethod('POST');
		req.setBody(xmlRQ);
		req.setHeader('Content-Type', 'application/xml; charset=UTF-8');
		req.setHeader('Accept', 'application/xml');
		req.setTimeout(60000);

		String xmlRS = null;
		Boolean STUB_FOR_NOW = false;
		if (Test.isRunningTest() || STUB_FOR_NOW)
		{
			stubGetPriceService(wo, lines);
			xmlRS = '<?xml version="1.0"?><WO>';
			for (String lineNumber : lineMap.keySet())
			{
				WorkOrderLineItem line = lineMap.get(lineNumber);
				xmlRS += '<Line><PartnerLineNumber>' + lineNumber + '</PartnerLineNumber><UnitPrice>' + line.Unit_Price__c + '</UnitPrice></Line>';
			}
            //xmlRS += '<error>NO PRICING CONDITION FOUND (STUB)</error>';
			xmlRS += '</WO>';
		}
		else
		{
			req.setEndpoint(url);
			Http http = new Http();
			HttpResponse res = http.send(req);
			xmlRS = res.getBody();
			System.debug('STATUS:' + res.getStatus());
			System.debug('STATUS_CODE:' + res.getStatusCode());
			if (res.getStatusCode() != 200)
			{
                throw new PricingException('Received HTTP Error Code: ' + res.getStatusCode() + ' - ' + res.getStatus());
			}
		}

		System.debug('PRICING RESPONSE XML: ' + xmlRS);

		//if (xmlRS == 'Success')
		//{
		//	// Temporary.. until Boomi returns actual RS XML
		//	stubGetPriceService(wo, lines);
		//	return null;
		//}

		String errorMsg = null;
		try
		{
			XmlStreamReader r = new XmlStreamReader(xmlRS);
			String currentElement = null;
			WorkOrderLineItem currentLine = null;
			while (r.hasNext())
			{
				r.next();
				if (r.getEventType() == XmlTag.START_ELEMENT)
				{
					currentElement = r.getLocalName();
				}
				else if (r.getEventType() == XmlTag.CHARACTERS)
				{
					if (currentElement == 'PartnerLineNumber')
					{
						String lineNumber = r.getText();
						currentLine = lineMap.get(lineNumber);
					}
					else if (currentElement == 'Currency' && currentLine != null)
					{
						String currencyCode = r.getText();
						//currentLine.CurrencyIsoCode = currencyCode;
						wo.CurrencyIsoCode = currencyCode;
						System.debug('PRICING: Received Currency Code: ' + currencyCode + ' for line: ' + currentLine);
					}
					else if (currentElement == 'UnitPrice' && currentLine != null)
					{
						Decimal amount = Decimal.valueOf(r.getText());
						currentLine.Unit_Price__c = amount / currentLine.Quantity__c; // THIS IS TEMPORARY
						currentLine.Status = 'Priced';
						System.debug('PRICING: Received price: ' + amount + ' for line: ' + currentLine);
					}
					else if (currentElement == 'error' || currentElement == 'errorMessage')
					{
						String msg = r.getText();
						if (String.isNotBlank(msg))
						{
							errorMsg = (errorMsg == null) ? 'Error returned from GetPrice Web Service: ' : errorMsg + ' : ';
							errorMsg += msg;
						}
					}
					currentElement = null; // Clear out this value, so only get 1st characters for each tag
				}
			}
		}
		catch(Exception ex)
		{
			System.debug('PRICING: Error Parsing Result: ' + ex);
			throw new PricingException('Error parsing result: ' + ex.getMessage());
		}

		return errorMsg;
	}

	/**
	 *  The following method looks up the Contract Discounts from the associated "Contract Entitlement" record,
	 *  and applies the correct Discount based on the Product Type (Labor, Travel, Parts, Consumables).
	 */
	public static void applyContractDiscounts(WorkOrder wo, List<WorkOrderLineItem> lines)
	{
		// Use the Product2.SVMXC__Product_Type__c to determine the correct...
		// ...Contract Discount to apply [Labor, Parts, Travel, Consumables]
		Id entId = wo.ContractEntitlement__c;
		if (entId != null)
		{
			// ITSFDC-350 Lookup WO + Ent + Fields needed for CDE Filter
			WorkOrder woDetails = [SELECT Id, WorkOrderNumber,
					ContractEntitlement__r.Labor_Discount_Covered__c,
					ContractEntitlement__r.Parts_Discount_Covered__c,
					ContractEntitlement__r.Travel_Discount_Covered__c,
					ContractEntitlement__r.ConsumableDiscountCovered__c,
					ContractEntitlement__r.ServicePartsDiscountCovered__c,
					AssetId, Asset.Product2Id,
					Location.SalesOrg__c, SAP_ActivityType__c
			FROM WorkOrder WHERE Id = :wo.Id];
			Entitlement ent = woDetails.ContractEntitlement__r;

			Set<Id> productIds = new Set<Id>();
			for (WorkOrderLineItem line : lines)
			{
				if (line.Part__c != null) {
					productIds.add(line.Part__c);
				}
			}

			if (productIds.isEmpty()) {
				return;
			}

			// ITSFDC-350 Adding Contract Discount Exception (CDE) Filter logic...
			String salesOrg = woDetails.Location.SalesOrg__c;
			String activityType = woDetails.SAP_ActivityType__c;
			Id ipProduct = woDetails.AssetId == null ? null : woDetails.Asset.Product2Id;

			Map<Id, Product2> productMap = new Map<Id, Product2>([SELECT Id, Name, Product_Type__c, Discount_Type__c,
				(SELECT Id, Discount_Type__c, Instrument_Product__c, Sales_Org__c, SAP_Activity_Type__c
				FROM Parts_Contract_Discount_Exceptions__r
				WHERE SAP_Activity_Type__c = :activityType
					AND (Sales_Org__c = NULL OR Sales_Org__c = :salesOrg)
					AND (Instrument_Product__c = NULL OR Instrument_Product__c = :ipProduct)
				ORDER BY Sales_Org__c NULLS LAST, Instrument_Product__c NULLS LAST)
				FROM Product2 WHERE Id IN :productIds]);
			for (WorkOrderLineItem line : lines)
			{
				Product2 prod = productMap.get(line.Part__c);
				// SVMXINT-621 Use new Discount Type field if it is populated
				String discountType = (prod != null) ?
						( String.isBlank(prod.Discount_Type__c) ?
								prod.Product_Type__c : prod.Discount_Type__c )
						: null;

				// ITSFDC-350 Adding Contract Discount Exception (CDE)
				if (prod != null && prod.Parts_Contract_Discount_Exceptions__r != null && !prod.Parts_Contract_Discount_Exceptions__r.isEmpty())
				{
					// NOTE: The above ORDER BY ensures we get the most relevant record first
					FS_Contract_Discount_Exception__c cde = prod.Parts_Contract_Discount_Exceptions__r[0];
					discountType = cde.Discount_Type__c;
				}

				if (discountType != null)
				{
					Decimal discount = null;
					if (discountType == 'Labor') {
						discount = ent.Labor_Discount_Covered__c;
					}
					else if (discountType == 'Travel') {
						discount = ent.Travel_Discount_Covered__c;
					}
					else if (discountType == 'Parts' || discountType == 'Other Parts') {
						discount = ent.Parts_Discount_Covered__c;
					}
					else if (discountType == 'Service Parts') {
						discount = ent.ServicePartsDiscountCovered__c;
					}
					else if (discountType == 'Consumable') {
						discount = ent.ConsumableDiscountCovered__c;
					}
					line.Discount_Type__c = discountType;
					line.ContractPercentDiscount__c = discount;
				}
			}

		}
	}

	/**
	 *  Fill in a random price for each line between 0.00 - 100.00.
	 */
	public static void stubGetPriceService(WorkOrder wo, List<WorkOrderLineItem> lines)
	{
		System.debug('STUBBING GetPrice Amounts.. ' + wo.WorkOrderNumber);
		for (WorkOrderLineItem line : lines)
		{
			Decimal qty = line.Quantity__c;
			System.debug('STUBBING GetPrice Amounts and qty is ' + qty);
			line.Unit_Price__c = Math.random() * 100.00;
			line.Status = 'Priced';
		}
	}

}