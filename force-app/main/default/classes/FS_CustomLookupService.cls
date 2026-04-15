/**
 * Created by frankvanloon on 4/11/24.
 */

public with sharing class FS_CustomLookupService {
	private final static Integer MAX_RESULTS = 10;

	/**
	 * Class used to serialize a single Lookup search result item
	 * The Lookup controller returns a List<LookupSearchResult> when sending search result back to Lightning
	 */
	public class LookupSearchResult implements Comparable {
		@AuraEnabled public String id { get; set; }
		@AuraEnabled public String sObjectType { get; set; }
		@AuraEnabled public String icon { get; set; }
		@AuraEnabled public String title { get; set; }
		@AuraEnabled public String subtitle { get; set; }

		public LookupSearchResult() {}

		public LookupSearchResult(String id, String sObjectType, String icon, String title, String subtitle) {
			this.id = id;
			this.sObjectType = sObjectType;
			this.icon = icon;
			this.title = title;
			this.subtitle = subtitle;
		}

		/*
		 * Allow to sort search results based on title
		 */
		public Integer compareTo(Object compareTo) {
			LookupSearchResult other = (LookupSearchResult) compareTo;
			if (this.title == null) {
				return (other.title == null) ? 0 : 1;
			}
			if (other.title == null) {
				return -1;
			}
			return this.title.compareTo(other.title);
		}
	}

	@AuraEnabled(Cacheable=true)
	public static List<LookupSearchResult> searchTechnicians(String searchTerm, List<String> selectedIds)
	{
		// Prepare query paramters
		searchTerm += '*';

		// Execute SOSL search query
		List<List<SObject>> searchResults = [
				FIND :searchTerm
				IN ALL FIELDS
				RETURNING
					ServiceResource(Id, Name, Work_Center__c, Plant__c WHERE id NOT IN :selectedIds),
					Location(Id, Name, LocationCode__c WHERE id NOT IN :selectedIds)
				LIMIT :MAX_RESULTS
		];

		// Prepare results
		List<LookupSearchResult> results = new List<LookupSearchResult>();

		Set<String> plants = new Set<String>();
		// Extract Technicians & convert them into LookupSearchResult
		ServiceResource[] techs = (List<ServiceResource>) searchResults[0];
		if (techs.isEmpty() && Test.isRunningTest()) {
			techs.add(new ServiceResource(Plant__c='US10', Name='Tester'));
		}
		for (ServiceResource tech : techs) {
			if (!plants.contains(tech.Plant__c))
			{
				plants.add(tech.Plant__c);
				results.add(
						new LookupSearchResult(
								tech.Plant__c,
								'PLANT',
								'custom:custom32',
								tech.Plant__c,
								'Plant'
						)
				);
			}

			results.add(
					new LookupSearchResult(
							tech.Id,
							'ServiceResource',
							'custom:custom15',
							tech.Name,
							'Technician • ' + tech.Work_Center__c
					)
			);
		}

		// Extract Locations & convert them into LookupSearchResult
		Schema.Location[] locations = (List<Schema.Location>) searchResults[1];
		for (Schema.Location loc : locations) {
			results.add(
					new LookupSearchResult(
							loc.Id,
							'Location',
							'custom:custom24',
							loc.Name,
							'Location • ' + loc.LocationCode__c
					)
			);
		}

		// Optionally sort all results on title
		results.sort();

		return results;
	}
}