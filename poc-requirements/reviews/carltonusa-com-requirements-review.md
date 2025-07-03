# Requirements Review: Carlton USA

**Date**: 2025-07-03  
**Version Reviewed**: v1.0  
**Overall Status**: 🟡 Yellow (Proceed with Cautions)

## Executive Summary

### PM Perspective
- **Schedule feasibility**: Feasible with conditions - 6-month timeline is aggressive but achievable with proper resource allocation
- **Resource needs**: 5-7 person team for 6 months minimum
- **Primary risks**: 
  1. Custom product configurator complexity underestimated
  2. Data extraction from vendor-locked system
  3. Parallel system costs during transition

### Architect Perspective  
- **Technical feasibility**: Feasible with conditions - all requirements achievable with Adobe Commerce B2B
- **Architecture readiness**: 8/10
- **Technical risks**: 
  1. Legacy data migration from ASP.NET
  2. Complex product customization rules
  3. Multi-system integration orchestration

## Detailed Findings

### 🟢 Strengths
Well-defined areas:

1. **Business Goals & Pain Points**: Crystal clear on why they need change - vendor lock-in, shipping errors, payment issues
2. **B2B Requirements**: Excellent articulation of buyer/payer/ship-to complexity
3. **Budget Reality**: Clear understanding of current spend ($27K/month) and implementation budget ($40-60K)
4. **Compliance Requirements**: Good identification of DOT/OSHA/Hazmat needs
5. **Phased Approach**: Logical 4-phase implementation plan

### 🟡 Recommendations
Areas to enhance:

| Section | Current State | Recommendation | Priority |
|---------|--------------|----------------|----------|
| **Virtual Catalogs** | Mentioned but undefined | Define if PDF generation or interactive experience | HIGH |
| **Sample Workflow** | Feature exists, process unknown | Map complete sample request-to-fulfillment process | HIGH |
| **Production Management** | 70% custom but no detail | Define production tracking & customer communication needs | HIGH |
| **Payment Distribution** | "Big chunk" EDI/ACH | Get exact percentages for architecture planning | MEDIUM |
| **Order History Migration** | Timeframe undefined | Define how many years of history needed | MEDIUM |
| **Email Platform** | TBD platform | Identify current platform for migration planning | MEDIUM |
| **Success Metrics** | Some vague (e.g., "profitable") | Define specific $ targets and KPIs | LOW |

### 🔴 Critical Gaps
Must address before proceeding:

1. **Data Extraction Strategy**
   - Issue: Vendor has triple lock-in (website, OMS, Dynamics)
   - Impact: Could block or severely delay migration
   - Resolution: Legal review of contract + technical extraction plan ASAP

2. **Custom Product Configurator Complexity**
   - Issue: 4-5 customization levels mentioned but logic unknown
   - Impact: Could require 2-3x estimated development time
   - Resolution: Deep dive session with product team + prototype highest complexity item

3. **CSR Workflow Details**
   - Issue: "Sub-30 second order lookup" but current process undefined
   - Impact: Cannot validate if target achievable
   - Resolution: Shadow CSRs for a day, time current processes

## Project Viability Assessment

### Triple Constraint Analysis
```
        SCOPE
         /\
        /  \
       /    \
      /      \
   TIME ---- COST

Current balance: Scope-heavy with tight budget
Recommendation: Consider MVP scope reduction or budget increase
```

### Go/No-Go Recommendation

**Verdict**: Proceed with Cautions

Conditions:
- [x] Client commitment confirmed (pain is real)
- [x] Adobe Commerce B2B can meet core needs
- [ ] Data extraction path must be validated
- [ ] Custom product complexity must be prototyped
- [ ] Additional 20% budget buffer recommended

## Risk-Adjusted Planning

### Critical Success Factors
1. **Early Vendor Extraction**
   - Why critical: Current vendor has triple lock-in
   - How to ensure: Legal review + parallel data export starting day 1

2. **Custom Product Prototype**
   - Why critical: 70% of business, highest complexity
   - How to ensure: Sprint 0 dedicated to configurator proof-of-concept

3. **Stakeholder Buy-in**
   - Why critical: 5 departments affected, only 2 engaged so far
   - How to ensure: Demos with each department before Phase 2

### Major Risks & Mitigations

| Risk | Probability | Impact | Mitigation | Owner |
|------|------------|---------|------------|-------|
| Data extraction blocked | MEDIUM | HIGH | Legal review, manual export backup plan | PM + Legal |
| Custom product complexity | HIGH | HIGH | Early prototype, iterative development | Architect |
| Integration delays | MEDIUM | MEDIUM | Parallel track, vendor engagement | Tech Lead |
| Staff adoption resistance | MEDIUM | MEDIUM | Early training, change champions | PM |
| Budget overrun | MEDIUM | HIGH | 20% buffer, phased delivery | PM |

## Resource Recommendations

### Core Team
- Project Manager: 50% dedication
- Solution Architect: 75% dedication Month 1, 25% ongoing
- Senior Developer (Custom Products): 100% dedication
- Senior Developer (Integrations): 100% dedication
- Developer (B2B Features): 100% dedication
- QA Engineer: 50% Month 1-3, 100% Month 4-6
- Business Analyst: 75% dedication

### Extended Team
- DevOps: 25% dedication (burst to 100% for go-live)
- UX/UI Designer: 50% Month 1-2 (custom configurator)
- Data Migration Specialist: 100% Month 2-5
- Training Specialist: 50% Month 5-6

## Technical Recommendations

### Architecture Refinements
1. **Caching Strategy**: Define approach for customer-specific pricing with performance
2. **Integration Middleware**: Consider iPaaS for Dynamics/Zoho orchestration
3. **Custom Product Engine**: Evaluate rules engine vs custom development
4. **Search Enhancement**: Plan for SKU pattern matching (partial numbers)

### Development Standards
- [x] Adobe Commerce coding standards apply
- [ ] Git workflow needs definition (GitFlow recommended)
- [ ] CI/CD pipeline must include performance tests
- [ ] Testing strategy needs 70% coverage minimum

### Performance Planning
- Target metrics defined: Yes (< 2s page load)
- Load testing planned: Not mentioned - REQUIRED
- Monitoring strategy: Not defined - REQUIRED
- CDN strategy: Yes (Fastly mentioned)

## Updated Timeline

### Recommended Phases
```mermaid
gantt
    title Risk-Adjusted Project Timeline
    dateFormat  YYYY-MM-DD
    section Sprint 0
    Legal/Extraction Review    :2024-01-01, 2w
    Custom Product Prototype   :2024-01-01, 2w
    section Phase 1
    Environment Setup         :2024-01-15, 1w
    Core B2B Development      :1w, 5w
    section Phase 2  
    Custom Configurator       :2w, 4w
    Integrations Start        :2w, 6w
    section Phase 3
    CSR Interface            :1w, 3w
    Testing & UAT            :2w, 3w
    section Phase 4
    Performance Tuning       :1w, 2w
    Training & Migration     :1w, 2w
    Go-Live & Stabilization  :1w, 2w
```

## Action Items

### Immediate (Before Task Creation)
1. [ ] Schedule legal review of Ability Commerce contract
2. [ ] Prototype most complex custom product configuration
3. [ ] Shadow CSRs to time current workflows
4. [ ] Get exact payment method percentages
5. [ ] Identify current email platform
6. [ ] Define order history migration timeframe

### During Planning
1. [ ] Create detailed integration specifications for each system
2. [ ] Design caching strategy for B2B pricing
3. [ ] Plan load testing scenarios (100 orders/minute target)
4. [ ] Establish branching and deployment strategy
5. [ ] Create compliance attribute taxonomy

### Risk Mitigation Setup
1. [ ] Establish vendor extraction contingency plan
2. [ ] Define budget escalation thresholds
3. [ ] Identify change champions in each department
4. [ ] Plan parallel running period

## Appendix: Requirement Scores

| Requirement Category | Clarity | Feasibility | Risk | Notes |
|---------------------|---------|-------------|------|-------|
| B2B Account Management | 5/5 | 5/5 | LOW | Native Adobe Commerce capability |
| Product Customization | 3/5 | 3/5 | HIGH | Complexity unknown |
| Internal Order Mgmt | 4/5 | 4/5 | MEDIUM | CSR efficiency critical |
| Shipping/Fulfillment | 4/5 | 4/5 | LOW | Shipper HQ proven |
| Payment Processing | 3/5 | 4/5 | MEDIUM | EDI/ACH needs detail |
| Compliance | 4/5 | 4/5 | LOW | Attribute-based approach |
| Catalog Management | 2/5 | 3/5 | MEDIUM | Virtual catalogs undefined |

## Summary Recommendations

### For Project Success:
1. **Add Sprint 0** for legal review and custom product prototype
2. **Increase budget** by 20% for contingency
3. **Extend timeline** by 2-3 weeks for proper testing
4. **Engage all stakeholders** before Phase 2 begins
5. **Define success metrics** more specifically

### Technical Priorities:
1. Validate data extraction immediately
2. Prototype complex product configuration
3. Design integration architecture with fallbacks
4. Plan for B2B performance at scale
5. Establish monitoring from day 1

---

**Review Completed By**: PM + Solutions Architect Review Process  
**Recommendation**: Proceed with cautions - address critical gaps in Sprint 0  
**Next Step**: Address action items, then proceed to task creation