/**
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
* Class Name      : DateTimeConverter
* Author          : Vibe X
* Created Date    : Apr 26, 2026
* Last Modified By: Vibe X
* Last Modified On: Apr 26, 2026
* Description     : This class implements for Convert DateTime
* Change History  :
*  Date          │   Author     │   Change
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
*  Apr 26, 2026  │ Vibe X   │ Initial version
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
*/
public with sharing class FindNearbyServiceTerritories {
    
    // Wrapper to parse JSON input
    public class GeoInput {
        public String city;
        public String state;
        public String country;
        public Decimal latitude;
        public Decimal longitude;
    }
    
    // Flow Input
    public class Input {
        @InvocableVariable(required=true)
        public String location;
    }
    
    // Flow Output
    public class Output {
        @InvocableVariable
        public List<DealerLocation> territories;
    }
    
    @InvocableMethod(label='Find Nearby Service Territories')
    public static List<Output> findTerritories(List<Input> inputs) {
        
        List<Output> results = new List<Output>();
        
        Output out = new Output();
        List<DealerLocation> nearby = new List<DealerLocation>();
        
        // Parse JSON → Apex object
        GeoInput geo = (GeoInput) JSON.deserialize(inputs[0].location, GeoInput.class);
        
        if (geo == null || geo.latitude == null || geo.longitude == null) {
            out.territories = nearby;
            results.add(out);
        } else {
            // Create input location
            Location inputLoc = Location.newInstance((Double)geo.latitude,(Double)geo.longitude);
            Location stLoc = null;
            Double distance = 0;
            Integer boundaryCheck = Integer.ValueOf(System.Label.BoundaryDistance);
            DealerLocation dealer = new DealerLocation();
            // Calculate distance
            for (ServiceTerritory st : [SELECT Id, Name, Latitude,Longitude
                                                 FROM ServiceTerritory
                                                 WHERE Latitude != NULL
                                                 AND Longitude != NULL]) {
                
                stLoc = Location.newInstance((Double)st.Latitude,(Double)st.Longitude);
                distance = inputLoc.getDistance(stLoc, 'mi');
                if (distance < boundaryCheck) {
                    dealer.id = st.Id;
                    dealer.name = st.Name;
                    nearby.add(dealer);
                }
            }
            
            out.territories = nearby;
            system.debug('%$%$%$ '+nearby);
            results.add(out);
        }
        
        return results;
    }
}