public with sharing class FS_ProductManager {

	private FS_ProductManager() {
	}

	public static void updateDeletedFlag(List<Product2> newProductList, Map<Id, Product2> oldProductMap)
	{
		if (!FS_Utility.isActive('Update Deleted Flag', 'Update delete flag in Product Sales and Product Plant, Delete Product Revision and Product Classification.'))
		{  return;  }

		//List<SMAX_PS_ProductRevision__c> prDeleteList = new List<SMAX_PS_ProductRevision__c>();
		List<Product_Classification__c> pcDeleteList = new List<Product_Classification__c>();
		List<Product_Sales__c> psUpdateList = new List<Product_Sales__c>();
		List<FS_ProductPlant__c> ppUpdateList = new List<FS_ProductPlant__c>();
		//Map<Id, List<SMAX_PS_ProductRevision__c>> prMap = new Map<Id, List<SMAX_PS_ProductRevision__c>>();
		Map<Id, List<Product_Classification__c>> pcMap = new Map<Id, List<Product_Classification__c>>();
		Map<Id, List<Product_Sales__c>> psMap = new Map<Id, List<Product_Sales__c>>();
		Map<Id, List<FS_ProductPlant__c>> ppMap = new Map<Id, List<FS_ProductPlant__c>>();
		Set<Id> productIds = new Set<Id>();

		// ITSFDC-350 Adding Contract Discount Exception (CDE)
		List<FS_Contract_Discount_Exception__c> cdeDeleteList = new List<FS_Contract_Discount_Exception__c>();
		Map<Id, List<FS_Contract_Discount_Exception__c>> cdeMap = new Map<Id, List<FS_Contract_Discount_Exception__c>>();

		// ITSFDC-507 Adding Extended Warranty Parts (EWP)
		List<FS_ExtendedWarrantyPart__c> ewpUpdateList = new List<FS_ExtendedWarrantyPart__c>();
		Map<Id, List<FS_ExtendedWarrantyPart__c>> ewpMap = new Map<Id, List<FS_ExtendedWarrantyPart__c>>();

		if (!newProductList.isEmpty()) {
			for (Product2 prod : newProductList)
			{
				if ( oldProductMap.get(prod.Id) != null
						&& oldProductMap.get(prod.Id).CompletedTxnNum__c != prod.CompletedTxnNum__c ) {
					productIds.add(prod.Id);
				}
			}
		}
		// Exit if no records are qualified
		if (productIds.isEmpty()) {
			return;
		}

		// List<SMAX_PS_ProductRevision__c> prList = new List<SMAX_PS_ProductRevision__c>([SELECT Id, Name, SMAX_PS_Product__c, SMAX_PS_LastTxnNum__c FROM SMAX_PS_ProductRevision__c WHERE SMAX_PS_Product__c IN :productIds]);

		List<Product_Classification__c> pcList = new List<Product_Classification__c>([SELECT Id, Name, Product__c, Last_Transaction_Number__c FROM Product_Classification__c WHERE Product__c IN :productIds]);

		List<Product_Sales__c> psList = new List<Product_Sales__c>([SELECT Id, Name, Product__c, Last_Transaction_Number__c, Deletion_Flag__c FROM Product_Sales__c WHERE Product__c IN :productIds]);

		List<FS_ProductPlant__c> ppList = new List<FS_ProductPlant__c>([SELECT Id, Name, Product__c, LastTxnNum__c, SAP_Deleted__c FROM FS_ProductPlant__c WHERE Product__c IN :productIds]);

		// ITSFDC-350 Adding Contract Discount Exception (CDE)
		List<FS_Contract_Discount_Exception__c> cdeList = new List<FS_Contract_Discount_Exception__c>([SELECT Id, Name, Parts_Product__c, Last_Txn_Number__c FROM FS_Contract_Discount_Exception__c WHERE Parts_Product__c IN :productIds]);

		// ITSFDC-507 Adding Extended Warranty Parts (EWP)
		List<FS_ExtendedWarrantyPart__c> ewpList = new List<FS_ExtendedWarrantyPart__c>([SELECT Id, Name, Equipment_Product__c, Last_Txn_Number__c FROM FS_ExtendedWarrantyPart__c WHERE Equipment_Product__c IN :productIds]);

		/*// Fill in Product Revision Map
		if (!prList.isEmpty()) {
		  for (SMAX_PS_ProductRevision__c pr : prList) {
			List<SMAX_PS_ProductRevision__c> listPR = new List<SMAX_PS_ProductRevision__c>();
			if(prMap.containsKey(pr.SMAX_PS_Product__c)) {
			  listPR = prMap.get(pr.SMAX_PS_Product__c);
			}
			listPR.add(pr);
			prMap.put(pr.SMAX_PS_Product__c, listPR);
		  }
		}*/

		// Fill in Product Classification Map
		if (!pcList.isEmpty()) {
			for (Product_Classification__c pc : pcList) {
				List<Product_Classification__c> listPC = new List<Product_Classification__c>();
				if(pcMap.containsKey(pc.Product__c)) {
					listPC = pcMap.get(pc.Product__c);
				}
				listPC.add(pc);
				pcMap.put(pc.Product__c, listPC);
			}
		}

		// Fill in Product Sales Map
		if (!psList.isEmpty()) {
			for (Product_Sales__c ps : psList) {
				List<Product_Sales__c> listPS = new List<Product_Sales__c>();
				if(psMap.containsKey(ps.Product__c)) {
					listPS = psMap.get(ps.Product__c);
				}
				listPS.add(ps);
				psMap.put(ps.Product__c, listPS);
			}
		}

		// Fill in Product Plant Map
		if (!ppList.isEmpty()) {
			for (FS_ProductPlant__c pp : ppList) {
				List<FS_ProductPlant__c> listPP = new List<FS_ProductPlant__c>();
				if(ppMap.containsKey(pp.Product__c)) {
					listPP = ppMap.get(pp.Product__c);
				}
				listPP.add(pp);
				ppMap.put(pp.Product__c, listPP);
			}
		}

		// ITSFDC-350 Fill in Contract Discount Exception Map
		if (!cdeList.isEmpty()) {
			for (FS_Contract_Discount_Exception__c cde : cdeList) {
				List<FS_Contract_Discount_Exception__c> listCDE = new List<FS_Contract_Discount_Exception__c>();
				if(cdeMap.containsKey(cde.Parts_Product__c)) {
					listCDE = cdeMap.get(cde.Parts_Product__c);
				}
				listCDE.add(cde);
				cdeMap.put(cde.Parts_Product__c, listCDE);
			}
		}

		// ITSFDC-507 Fill in Extended Warranty Parts Map
		if (!ewpList.isEmpty()) {
			for (FS_ExtendedWarrantyPart__c ewp : ewpList) {
				List<FS_ExtendedWarrantyPart__c> listEWP = new List<FS_ExtendedWarrantyPart__c>();
				if(ewpMap.containsKey(ewp.Equipment_Product__c)) {
					listEWP = ewpMap.get(ewp.Equipment_Product__c);
				}
				listEWP.add(ewp);
				ewpMap.put(ewp.Equipment_Product__c, listEWP);
			}
		}

		// Main process
		if (!newProductList.isEmpty()) {
			for ( Product2 prod : newProductList ) {
				// create list of records to be deleted in Product Revision
				/*List<SMAX_PS_ProductRevision__c> listPR = new List<SMAX_PS_ProductRevision__c>();
				if ( prMap.containsKey(prod.Id) ) {
				  listPR = prMap.get(prod.Id);
				  if (!listPR.isEmpty()) {
					for (SMAX_PS_ProductRevision__c pr : listPR) {
					  if (pr.SMAX_PS_LastTxnNum__c != prod.SMAX_PS_CompletedTxnNum__c) {
						prDeleteList.add(pr);
					  }
					}
				  }
				}*/
				// create list of records to be deleted in Product Classification
				List<Product_Classification__c> listPC = new List<Product_Classification__c>();
				if ( pcMap.containsKey(prod.Id) ) {
					listPC = pcMap.get(prod.Id);
					if (!listPC.isEmpty()) {
						for (Product_Classification__c pc : listPC) {
							if (pc.Last_Transaction_Number__c != prod.CompletedTxnNum__c) {
								pcDeleteList.add(pc);
							}
						}
					}
				}
				// create list of records to be updated in Product Sales
				List<Product_Sales__c> listPS = new List<Product_Sales__c>();
				if ( psMap.containsKey(prod.Id) ) {
					listPS = psMap.get(prod.Id);
					if (!listPS.isEmpty()) {
						for (Product_Sales__c ps : listPS) {
							if (ps.Last_Transaction_Number__c != prod.CompletedTxnNum__c) {
								ps.Deletion_Flag__c = true;
								psUpdateList.add(ps);
							}
						}
					}
				}
				// create list of records to be updated in Product Plant
				List<FS_ProductPlant__c> listPP = new List<FS_ProductPlant__c>();
				if ( ppMap.containsKey(prod.Id) ) {
					listPP = ppMap.get(prod.Id);
					if (!listPP.isEmpty()) {
						for (FS_ProductPlant__c pp : listPP) {
							if (pp.LastTxnNum__c != prod.CompletedTxnNum__c) {
								pp.SAP_Deleted__c = true;
								ppUpdateList.add(pp);
							}
						}
					}
				}
				// ITSFDC-350 create list of records to be deleted in Contract Discount Exception
				List<FS_Contract_Discount_Exception__c> listCDE = new List<FS_Contract_Discount_Exception__c>();
				if ( cdeMap.containsKey(prod.Id) ) {
					listCDE = cdeMap.get(prod.Id);
					if (!listCDE.isEmpty()) {
						for (FS_Contract_Discount_Exception__c cde : listCDE) {
							if (cde.Last_Txn_Number__c != prod.CompletedTxnNum__c) {
								cdeDeleteList.add(cde);
							}
						}
					}
				}
				// ITSFDC-507 create list of records to be updated in Extended Warranty Parts
				List<FS_ExtendedWarrantyPart__c> listEWP = new List<FS_ExtendedWarrantyPart__c>();
				if ( ewpMap.containsKey(prod.Id) ) {
					listEWP = ewpMap.get(prod.Id);
					if (!listEWP.isEmpty()) {
						for (FS_ExtendedWarrantyPart__c ewp : listEWP) {
							if (ewp.Last_Txn_Number__c != prod.CompletedTxnNum__c) {
								ewp.Is_Deleted__c = true;
								ewpUpdateList.add(ewp);
							}
						}
					}
				}
			}
			// Delete Product Revision, Product Classification and Update Product Sales, Product Plant
			/* if (!prDeleteList.isEmpty()) {
			   delete prDeleteList;
			 }*/
			if (!pcDeleteList.isEmpty()) {
				delete pcDeleteList;
			}
			if (!psUpdateList.isEmpty()) {
				update psUpdateList;
			}
			if (!ppUpdateList.isEmpty()) {
				update ppUpdateList;
			}
			if (!cdeDeleteList.isEmpty()) {
				delete cdeDeleteList;
			}
			if (!ewpUpdateList.isEmpty()) {
				update ewpUpdateList;
			}
		}
	}

	public static void deleteProductChildRecords(List<Product2> prodOldList)
	{

		if (!FS_Utility.isActive('Delete Product Child Records', 'Deletes related Product Sales, Product Plant, Product Revision and Product Classification when a Product is deleted.'))
		{  return;  }

		Set<Id> prodIdSet = new Set<Id>();

		if (!prodOldList.isEmpty()) {
			for (Product2 prd : prodOldList) {
				prodIdSet.add(prd.Id);
			}
		}
		System.debug('prodIdSet->'+prodIdSet);
		// Exit if no records are qualified
		if (prodIdSet.isEmpty()) {
			return;
		}

		// Delete the related Revision records
		/*List<SMAX_PS_ProductRevision__c> prodRevList = [SELECT Id FROM SMAX_PS_ProductRevision__c WHERE SMAX_PS_Product__c IN :prodIdSet];
		if (!prodRevList.isEmpty()) {
		  delete prodRevList;
		}*/

		// Delete the related Classification records
		List<Product_Classification__c> prodClsList = [SELECT Id FROM Product_Classification__c WHERE Product__c IN :prodIdSet];
		if (!prodClsList.isEmpty()) {
			delete prodClsList;
		}

		// Delete the related Sales records
		List<Product_Sales__c> prodSalesList = [SELECT Id FROM Product_Sales__c WHERE Product__c IN :prodIdSet];
		if (!prodSalesList.isEmpty()) {
			delete prodSalesList;
		}

		// Delete the related Plant records
		List<FS_ProductPlant__c> prodPlantList = [SELECT Id FROM FS_ProductPlant__c WHERE Product__c IN :prodIdSet];
		if (!prodPlantList.isEmpty()) {
			delete prodPlantList;
		}

		// ITSFDC-350 Delete the related Contract Discount Exception (CDE)
		List<FS_Contract_Discount_Exception__c> cdeList = [SELECT Id FROM FS_Contract_Discount_Exception__c WHERE Parts_Product__c IN :prodIdSet];
		if (!cdeList.isEmpty()) {
			delete cdeList;
		}

		// ITSFDC-507 Delete the related Extended Warranty Parts (EWP)
		List<FS_ExtendedWarrantyPart__c> ewpList = [SELECT Id FROM FS_ExtendedWarrantyPart__c WHERE Equipment_Product__c IN :prodIdSet];
		if (!ewpList.isEmpty()) {
			delete ewpList;
		}

	}

	/* public static void processProductClassifications(List<SMAX_PS_ProductClassification__c> pcList, Map<Id, SMAX_PS_ProductClassification__c> oldMap)
	 {
	   Map<Id, Product2> prodMap = new Map<Id, Product2>();
	   for(SMAX_PS_ProductClassification__c pc : pcList)
	   {
		 if (pc.SMAX_PS_Characteristic__c == 'PE Medical Device' || pc.SMAX_PS_Characteristic__c == 'PE_MEDICAL_DEVICE')
		 {
		   Product2 p = new Product2();
		   p.Id = pc.SMAX_PS_Product__c;
		   p.SMAX_PS_Medical_Classification__c = pc.SMAX_PS_Value__c;
		   prodMap.put(p.Id, p);
		 }
	   }

	   if (!prodMap.isEmpty())
	   {
		 Database.update(prodMap.values(), false);
	   }
	 }*/

	public static void processProductSales(List<Product_Sales__c> psList, Map<Id, Product_Sales__c> oldMap)
	{
		Set<Id> productIds = new Set<Id>();
		for(Product_Sales__c pSales : psList)
		{
			productIds.add(pSales.Product__c);
		}

		Map<Id, Product2> productMap = new Map<Id, Product2>([SELECT Id, Name,
				Description, Part_Number__c, Product_Type__c, Activity_Type__c
			FROM Product2 WHERE Id IN :productIds]);
		for(Product_Sales__c pSales : psList)
		{
			Product2 prod = productMap.get(pSales.Product__c);

			pSales.Part_Description__c = prod.Description;
			if (pSales.Part_Description__c != null && pSales.Part_Description__c.length() > 255)
			{
				pSales.Part_Description__c = pSales.Part_Description__c.substring(0, 252) + '...';
			}

			pSales.Part_Number__c = prod.Part_Number__c;
			pSales.Product_Type__c = prod.Product_Type__c;
			pSales.SAP_Activity_Type__c = prod.Activity_Type__c;
		}
	}

	// ITSFDC-509 Lookup the "Return Part" from the "Return Part Number"
	public static void processProductPlant(List<FS_ProductPlant__c> ppList, Map<Id, FS_ProductPlant__c> oldMap)
	{
		// 2022-04-20 Tony ITSVMX-562 Modify the replenishment parts ordering process
		Set<String> refurbPartNumbers = new Set<String>();
		Set<String> productCodes = new Set<String>();
		for(FS_ProductPlant__c pPlant : ppList)
		{
			if (pPlant.Return_Part__c == null && pPlant.Return_Part_Number__c != null)
			{
				productCodes.add(pPlant.Return_Part_Number__c);
			}

			// 2022-04-20 Tony ITSVMX-562 Get the list of Refurbished Part Numbers that don't have a Refurbished Part
			if (pPlant.Refurbished_Part__c == null && pPlant.Refurbished_Part_Number__c != null)
			{
				refurbPartNumbers.add(pPlant.Refurbished_Part_Number__c);
			}
		}

		if (productCodes.isEmpty() && refurbPartNumbers.isEmpty())
		{
			return;
		}

		Map<String, Product2> productMap = new Map<String, Product2>();
		for (Product2 prod : [SELECT Id, Name, Part_Number__c FROM Product2 WHERE Part_Number__c IN :productCodes])
		{
			productMap.put(prod.Part_Number__c, prod);
		}

		// 2022-04-20 Tony ITSVMX-562 Get a Map of the Refurbished Part Numbers to Products
		Map<String, Product2> refurbPartMap = new Map<String, Product2>();
		for (Product2 prod : [SELECT Id, Name, Part_Number__c FROM Product2 WHERE Part_Number__c IN :refurbPartNumbers])
		{
			refurbPartMap.put(prod.Part_Number__c, prod);
		}

		for(FS_ProductPlant__c pPlant : ppList)
		{
			if (pPlant.Return_Part__c == null && pPlant.Return_Part_Number__c != null)
			{
				Product2 prod = productMap.get(pPlant.Return_Part_Number__c);
				if (prod != null)
				{
					pPlant.Return_Part__c = prod.Id;
				}
			}

			// 2022-04-20 Tony ITSVMX-562 If there is a Refurbished Part Numbers but no Refurbished Part then add it
			if (pPlant.Refurbished_Part__c == null && pPlant.Refurbished_Part_Number__c != null)
			{
				Product2 refurbPart = refurbPartMap.get(pPlant.Refurbished_Part_Number__c);
				if (refurbPart != null)
				{
					pPlant.Refurbished_Part__c = refurbPart.Id;
				}
			}
		}
	}

}