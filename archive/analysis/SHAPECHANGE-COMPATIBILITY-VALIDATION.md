# ShapeChange Compatibility Validation Report

Generated: 2025-11-11 16:33:07

## Statistics

### urbanObject (URO)

| Metric | Reference | Generated | Match |
| ------ | --------- | --------- | ----- |
| Imports | 12 | 11 | ✗ |
| Elements | 1234 | 324 | ✗ |
| Complex types | 341 | 487 | ✗ |
| Simple types | 8 | 0 | ✗ |
| Ade hooks | 99 | 92 | ✗ |

### urbanFunction (URF)

| Metric | Reference | Generated | Match |
| ------ | --------- | --------- | ----- |
| Imports | 3 | 1 | ✗ |
| Elements | 696 | 208 | ✗ |
| Complex types | 322 | 416 | ✗ |
| Simple types | 0 | 0 | ✓ |
| Ade hooks | 0 | 0 | ✓ |

## Differences Found

### urbanObject (URO)

#### Attribute Form Default

- Reference: unqualified, Generated: missing

#### Missing Imports

- http://www.opengis.net/citygml/2.0, http://www.opengis.net/gml

#### Extra Imports

- http://www.opengis.net/gml/3.2

#### Missing Elements (981)

- AbstractConstruction, AbstractPointCloud, FishingPortCapacity, FishingPortFacility, LandUseAttribute

#### Extra Elements (71)

- AbstructConstruction, BridgeAttribute, BuildingDisasterRiskAttribute, BuildingFloodingRiskAttribute, BuildingHighTideRiskAttribute

#### Element BuildingUsecaseAttribute substitutionGroup

- Reference: uro:BuildingAttribute, Generated: 

#### Element CityFurnitureDetailAttribute substitutionGroup

- Reference: uro:CityFurnitureAttribute, Generated: 

#### Element ConstructionInstallation substitutionGroup

- Reference: core:_CityObject, Generated: uro:_CityObject

#### Element IfcGroup abstract

- Reference: , Generated: true

#### Element IfcSpatialStructureElement abstract

- Reference: true, Generated: 

#### Element LandUseDetailAttribute substitutionGroup

- Reference: uro:LandUseAttribute, Generated: 

#### Element OtherConstruction substitutionGroup

- Reference: uro:AbstractConstruction, Generated: uro:AbstructConstruction

#### Element PublicLand substitutionGroup

- Reference: luse:LandUse, Generated: uro:LandUse

#### Element RoadStructureAttribute substitutionGroup

- Reference: uro:RoadAttribute, Generated: 

#### Element TrafficAreaStructureAttribute substitutionGroup

- Reference: uro:TrafficAreaAttribute, Generated: 

#### Element TrafficVolumeAttribute substitutionGroup

- Reference: uro:RoadAttribute, Generated: 

#### Element UndergroundBuilding substitutionGroup

- Reference: bldg:_AbstractBuilding, Generated: uro:_AbstractBuilding

#### Element UtilityLink abstract

- Reference: true, Generated: 

#### Element UtilityNetworkElement substitutionGroup

- Reference: frn:CityFurniture, Generated: uro:CityFurniture

#### Element UtilityNetworkElement abstract

- Reference: true, Generated: 

#### Element UtilityNode abstract

- Reference: true, Generated: 

#### Element UtilityNodeContainer abstract

- Reference: true, Generated: 

#### Element Waterway substitutionGroup

- Reference: tran:TransportationComplex, Generated: uro:TrafficComplex

#### Element _BoundarySurface substitutionGroup

- Reference: core:_CityObject, Generated: uro:_CityObject

#### Element _BoundarySurface abstract

- Reference: true, Generated: 

#### Element bridStructureAttribute type

- Reference: uro:BridgeStructureAttributePropertyType, Generated: uro:ConstructionStructureAttributePropertyType

#### Element tunStructureAttribute type

- Reference: uro:TunnelStructureAttributePropertyType, Generated: uro:ConstructionStructureAttributePropertyType

#### Missing Complex Types (26)

- AbstractConstructionPropertyType, AbstractConstructionType, AbstractPointCloudPropertyType, AbstractPointCloudType, FishingPortCapacityPropertyType

#### Extra Complex Types (172)

- AbstructConstructionPropertyType, AbstructConstructionType, BridgeAttributePropertyType, BridgeAttributeType, BuildingDisasterRiskAttributePropertyType

#### ComplexType AppurtenanceType sequence children

- Reference: 1 elements, Generated: 0 elements

#### ComplexType BridgeFunctionalAttributeType sequence children

- Reference: 2 elements, Generated: 0 elements

#### Missing Simple Types (8)

- ConditionOfConstructionValue, HightStatusValue, IFCStateEnum, IfcElementCompositionEnum, IfcSIPrefix, IfcTransportElementTypeEnum, IfcUnitEnum, ifcInternalOrExternalEnum

#### Missing ADE Hooks (7)

- bldgUsecaseAttribute, bridFunctionalAttribute, fiscalYearOfPublication, language, pointCloud, tranUsecaseAttribute, tunFunctionalAttribute

### urbanFunction (URF)

#### Attribute Form Default

- Reference: unqualified, Generated: missing

#### Missing Imports

- http://www.opengis.net/citygml/2.0, http://www.opengis.net/gml, https://www.geospatial.jp/iur/uro/3.2

#### Extra Imports

- http://www.opengis.net/gml/3.2

#### Missing Elements (537)

- NumberOfHouseholds, Target, acreage, activityRestrictionInFarmland, address

#### Extra Elements (49)

- AccomodationType, AreaClassicificationType, CityObjectGroup, CommutingPopulationType, DisasterPreventionBaseType

#### Element DevelopmentProject substitutionGroup

- Reference: urf:_UrbanFunction, Generated: urf:Zone

#### Element _UrbanFunction substitutionGroup

- Reference: core:_CityObject, Generated: urf:_CityObject

#### Missing Complex Types (4)

- NumberOfHouseholdsPropertyType, NumberOfHouseholdsType, TargetPropertyType, TargetType

#### Extra Complex Types (98)

- AccomodationTypePropertyType, AccomodationTypeType, AreaClassicificationTypePropertyType, AreaClassicificationTypeType, CityObjectGroupPropertyType

#### ComplexType AdministrationType sequence children

- Reference: 1 elements, Generated: 0 elements

#### ComplexType AgreementType sequence children

- Reference: 2 elements, Generated: 0 elements

