# Task: Legal Review of Ability Commerce Contract

**ID**: T001  
**Category**: Setup & Risk Mitigation  
**Priority**: CRITICAL  
**Status**: TODO

## Description
Review the current Ability Commerce contract to determine data ownership rights, extraction capabilities, and any legal barriers to migration. This is a blocking task that must be completed before any data extraction efforts begin.

## Requirements
- Reference: Risk Assessment - Vendor lock-in extraction (HIGH/MEDIUM)
- Review finding: "Vendor has triple lock-in (website, OMS, Dynamics)"

## Implementation Steps
1. Obtain complete copy of current Ability Commerce contract
2. Legal counsel review for:
   - Data ownership clauses
   - Export restrictions
   - Non-compete clauses
   - Termination requirements
   - Notice periods
3. Document any restrictions or requirements
4. Create legal extraction plan
5. Identify negotiation points if needed

## Definition of Done
- [ ] Contract reviewed by legal counsel
- [ ] Data ownership rights confirmed in writing
- [ ] Export capabilities documented
- [ ] Risk mitigation plan created
- [ ] Go/no-go decision documented
- [ ] Stakeholder approval obtained

## Acceptance Criteria
- Legal opinion provided on data extraction rights
- Clear documentation of what can/cannot be exported
- Timeline for contract termination defined
- Backup plan created if extraction blocked

## Technical Notes
- Current system: ASP.NET WebForms
- Database: Unknown (likely SQL Server)
- Triple lock-in: Website + OMS + Dynamics reseller
- Need to identify all data sources

## Estimated Effort
- **Complexity**: High
- **Hours**: 16 hours (2 days)
- **Resources**: Legal counsel + PM

## Dependencies
- **Depends on**: None (first task)
- **Blocks**: T002 (Data Extraction Plan), T010 (Product Catalog Migration)

## Risk Factors
- Contract may prohibit data extraction
- Vendor may charge extraction fees
- Legal review may take longer than estimated

## Notes
This is the most critical path item. If we cannot extract data legally, the entire project approach must be reconsidered. Consider having preliminary discussion with Ability Commerce about "partnership transition" to avoid adversarial relationship.