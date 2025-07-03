# POC Requirements Document: Carlton USA Adobe Commerce B2B Migration

**Project**: Carlton Industries E-commerce Platform Migration  
**Client**: Carlton USA (carltonusa.com)  
**Generated**: 2025-07-03  
**Version**: 1.0  
**Confidence Level**: 7.5/10  

## Executive Summary

Carlton USA requires migration from a legacy ASP.NET WebForms platform (Ability Commerce) to Adobe Commerce B2B. This migration addresses critical business pain points including vendor lock-in, inability to calculate real-time shipping rates, and lost customers due to payment processing issues. The platform must support complex B2B relationships, 70% custom product manufacturing, and compliance with DOT/OSHA/Hazmat regulations.

### Key Business Metrics
- **Current State**: $17K/month online revenue (unprofitable)
- **Monthly Technology Spend**: $27K ($10K hosting, $7.5K Google Ads, $10K email)
- **Implementation Budget**: $40-60K
- **Company Size**: 28 employees
- **Timeline**: 3-4 months for decision

## Business Context

### Company Overview
- **Industry**: Safety & Compliance Products
- **Business Model**: B2B exclusively
- **Product Mix**: 70% custom manufactured, 30% stock items
- **Catalog Size**: 13,000 SKUs (actively sell ~900)
- **Target Market**: Chemical companies, utilities, transportation
- **Competitors**: Uline, Labelmaster, Sign Warehouse

### Critical Business Goals
1. **Reduce operational overhead** - "We spend more time running our systems than we do running the business"
2. **Achieve web profitability** - Currently losing money despite $27K/month spend
3. **Eliminate shipping calculation errors** - $15 quoted vs $67 actual causing customer loss
4. **Fix payment processing issues** - Multiple credit card charges losing customers

## Functional Requirements

### 1. B2B Account Management (CRITICAL)
**Requirement**: Support complex B2B relationships with separate entities
- **Buyer**: Person placing the order
- **Payer**: Company/entity handling payment (may be different)
- **Ship-to**: Multiple delivery locations (up to 150 per account)

**Success Criteria**:
- Single buyer can order for multiple locations with central billing
- Separate permissions for buyers vs payers
- Ship-to address book with 150+ locations per account

### 2. Product Configuration & Customization (CRITICAL)
**Requirement**: Support 4-5 levels of customization per product
- Material selection (polyvinyl, rigid vinyl, aluminum, etc.)
- Size variations with radius options
- Hole drilling specifications
- Finishing options
- Compliance certifications

**Success Criteria**:
- Dynamic pricing based on all customization selections
- Visual product configurator
- Save custom configurations for reorder
- Bulk custom order capability

### 3. Internal Order Management (CRITICAL)
**Requirement**: CSR phone order interface
- Full customer view while on phone
- Quick order entry
- Access to full order history
- Manual price adjustments
- Production status visibility

**Success Criteria**:
- Sub-30 second order lookup
- Keyboard shortcuts for common tasks
- Real-time inventory visibility
- Order modification capabilities

### 4. Shipping & Fulfillment (HIGH)
**Requirement**: Complex fulfillment scenarios
- Real-time shipping calculation (Shipper HQ integration)
- Hold-to-complete orders for consolidated shipping
- Drop-ship from vendors
- Multi-location split shipments
- Production item lead times

**Success Criteria**:
- 100% accurate shipping quotes
- Automated vendor drop-ship orders
- Consolidated shipment management
- Production status tracking

### 5. Payment Processing (HIGH)
**Requirement**: Multiple B2B payment methods
- EDI/ACH processing
- Single-use credit cards ($150K+ orders)
- Net terms with credit limits
- Standard credit card processing

**Success Criteria**:
- No duplicate charges
- Automated credit application
- PO-based ordering
- Terms management

### 6. Compliance & Regulatory (HIGH)
**Requirement**: Industry-specific compliance features
- DOT placards categorization
- OSHA compliance indicators
- Hazmat shipping requirements
- California Prop 65 warnings
- State-specific regulations

**Success Criteria**:
- Automated compliance warnings
- Filterable by compliance type
- Downloadable certificates
- Audit trail for compliance

### 7. Catalog Management (MEDIUM)
**Features Identified**:
- Virtual catalog generation
- Multiple navigation paths to same products
- Quick order by SKU
- Sample request workflow
- Minimum order quantities

**Needs Clarification**:
- Virtual catalog format (PDF vs interactive)
- Sample approval workflow
- Customer-specific catalogs

## Technical Requirements

### Platform Specifications
- **Recommended**: Adobe Commerce B2B Edition
- **Hosting**: Adobe Commerce Cloud
- **Current Performance**: 55/100 → Target: 85+/100
- **Mobile**: Responsive design required
- **Search**: Elasticsearch with item number quick search

### Integration Requirements

| System | Purpose | Priority | Method |
|--------|---------|----------|---------|
| **Shipper HQ** | Real-time shipping rates | CRITICAL | Native integration |
| **Microsoft Dynamics** | Accounting/GL posting | HIGH | REST API |
| **Zoho CRM** | Customer relationship data | MEDIUM | API sync |
| **Email Platform** | 100K bi-monthly campaigns | MEDIUM | TBD platform |
| **Chase Payment Tech** | Merchant processing | HIGH | Payment gateway |

### Data Migration Requirements
- 13,000 SKUs with variants
- Customer accounts with multi-level relationships
- Order history (define timeframe)
- Compliance metadata
- URL redirects from .aspx

### Performance Requirements
- Page load: < 2 seconds
- Concurrent users: 100+
- Order processing: 100 orders/minute
- Search response: < 500ms
- 99.9% uptime

## Gap Analysis

### Critical Gaps Requiring Clarification
1. **Virtual Catalog Details**
   - Current format and usage
   - Update frequency
   - Customer segmentation needs

2. **Sample Request Workflow**
   - Approval process
   - Cost handling
   - Fulfillment integration

3. **Production Management**
   - Lead time communication
   - Status tracking requirements
   - Customer proof approval

4. **Payment Method Distribution**
   - % EDI/ACH vs credit cards
   - Single-use card frequency
   - Terms requirements

### Technical Gaps
- Custom product configurator complexity
- Pricing rule requirements
- Integration data mapping
- Compliance attribute taxonomy

## Risk Assessment

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **Vendor lock-in extraction** | HIGH | MEDIUM | Data ownership agreement, phased migration |
| **Custom product complexity** | HIGH | HIGH | Prototype early, iterative development |
| **Staff adoption** | MEDIUM | MEDIUM | Training plan, phased rollout |
| **Integration delays** | MEDIUM | MEDIUM | Parallel development tracks |
| **Compliance requirements** | HIGH | LOW | Detailed requirement gathering |

## Success Metrics

### 6-Month Post-Launch
- **Revenue**: Online channel profitable
- **Efficiency**: 50% reduction in order processing time
- **Customer Satisfaction**: Zero payment processing complaints
- **Shipping Accuracy**: 100% correct quotes
- **Adoption**: 60% of B2B customers using online

### 12-Month Goals
- **Revenue Growth**: 25% increase in online revenue
- **Cost Reduction**: 20% reduction in operational overhead
- **Market Share**: Win back lost customers
- **Expansion**: Add new B2B features based on feedback

## Recommended Approach

### Phase 1: Foundation (Months 1-2)
- Environment setup
- Basic B2B configuration
- Product catalog migration
- Shipper HQ integration

### Phase 2: Core Features (Months 2-4)
- Custom product configurator
- Company account structure
- Payment processing setup
- CSR order interface

### Phase 3: Advanced Features (Months 4-5)
- Integrations (Dynamics, Zoho)
- Compliance features
- Performance optimization
- Email marketing setup

### Phase 4: Launch Preparation (Month 6)
- User acceptance testing
- Staff training
- Data migration finalization
- Go-live planning

## Budget Considerations

### One-Time Costs
- Implementation: $40-60K (stated budget)
- Data migration: Included
- Training: Included
- Third-party licenses: TBD

### Ongoing Costs
- Adobe Commerce: $2-4K/month (est.)
- Hosting: $2-3K/month (from current $10K)
- Maintenance: 20% of implementation annually

### ROI Projections
- Current spend: $27K/month
- Projected savings: $10-15K/month
- Break-even: 4-6 months post-launch

## Next Steps

### Immediate Actions Required
1. **Send clarification questions** (see attached document)
2. **Schedule stakeholder demos** with finance, operations, sales managers
3. **Technical deep dive** on custom product configurations
4. **Review Ability Commerce contract** for extraction terms

### Pre-Contract Requirements
1. Detailed integration specifications
2. Compliance requirement documentation
3. Sample data for prototyping
4. Current system access for analysis

### Decision Criteria
- [ ] Local Austin partner availability
- [ ] Reference checks with similar B2B companies
- [ ] Proof of concept for custom products
- [ ] Integration feasibility confirmed
- [ ] Total cost of ownership calculated

---

## Appendices

### A. Clarification Questions
See accompanying document: `carltonusa-com-clarification-needed.md`

### B. Technical Analysis
See accompanying document: `carltonusa-com-architecture-review.md`

### C. Communication Insights
See accompanying document: `carltonusa-com-communication-review.md`

### D. Meeting Participants
- Rick Carlton (Owner/Decision Maker)
- Jennifer Carlton (Marketing/Graphics - 19 years)
- Accounting Manager (future participant)
- Purchasing Operations Manager (future participant)
- Sales Manager (future participant)

### E. Compliance Requirements
- DOT hazmat placards
- OSHA safety signage
- California Prop 65
- Industry-specific certifications

---

**Document Generated By**: POC Requirements Generator  
**Confidence Level**: 7.5/10  
**Review Status**: Ready for client validation