# Clarification Questions for Carlton USA

**Generated**: 2025-07-03
**Priority**: High - Send before requirements generation

## Critical Business Process Questions

### 1. Virtual Catalog Details
**Context**: Website shows "Virtual catalogs" as a feature
**Need to understand**: 
- Are these PDF downloads or interactive online experiences?
- How often are they updated?
- Do different customer segments see different catalogs?
- What's the current creation/maintenance process?

### 2. Sample Request Workflow
**Context**: "Request samples" feature exists but process unclear
**Need to understand**:
- Who approves sample requests?
- Are samples free or charged?
- How are they fulfilled (separate from regular orders)?
- Is there a limit per customer?
- How do you track sample-to-order conversion?

### 3. Production/Custom Item Management
**Context**: 70% of business is custom, current system doesn't handle production items
**Need to understand**:
- What's the typical lead time for custom items?
- How do you currently communicate production status to customers?
- Do you need customers to approve proofs/designs?
- How do you handle rush orders?
- What triggers production - payment or PO?

### 4. EDI/ACH Payment Distribution
**Context**: Multiple payment methods mentioned but ratios unclear
**Need to understand**:
- What percentage of orders are:
  - EDI/ACH?
  - Single-use credit cards?
  - Regular credit cards?
  - Terms/invoicing?
- Do payment methods vary by customer size?

### 5. Multi-Location Shipping Complexity
**Context**: One buyer shipping to 150 locations mentioned
**Need to understand**:
- How common are multi-location orders?
- Do you need to:
  - Split quantities across locations?
  - Schedule different delivery dates?
  - Track confirmations separately?
  - Generate separate packing slips?
- How do you handle partial shipments to different locations?

## Technical Integration Questions

### 6. Microsoft Dynamics Data Flow
**Context**: Currently using high-level GL export via CSV
**Need to understand**:
- Exactly which data fields need to sync?
- Is customer-level detail needed or just GL summaries?
- How do you handle returns/credits in the sync?
- Any other systems reading from Dynamics that need order data?

### 7. Email Marketing Platform Details
**Context**: Spending $10K/month on email to 100K contacts
**Need to understand**:
- Which email platform are you using?
- What triggers should add customers to lists?
- Do you need segmentation based on purchase history?
- Any automated campaigns based on behavior?

### 8. Compliance and Regulatory Display
**Context**: DOT, OSHA, Hazmat, Prop 65 requirements
**Need to understand**:
- Which compliance warnings need to display by product?
- Are there state-specific requirements?
- Do you need compliance documentation/certs available for download?
- Any industry-specific checkout requirements?

## Operational Questions

### 9. CSR Phone Order Process
**Context**: Internal orders are critical requirement
**Need to understand**:
- Average call duration for an order?
- Most complex order scenario for CSRs?
- Do CSRs need to see customer's full history while on phone?
- Any specific keyboard shortcuts or quick-entry needs?

### 10. Inventory and Fulfillment
**Context**: Mix of stock, custom, and drop-ship
**Need to understand**:
- How do you currently track inventory across locations?
- What triggers reorder points?
- How do you manage drop-ship vendor relationships?
- Any special kitting or bundling requirements?

## Strategic Questions

### 11. Success Metrics
**What would success look like 6 months after go-live?**
- Specific efficiency gains?
- Revenue targets for online channel?
- Customer satisfaction improvements?
- Order processing time reductions?

### 12. Change Management
**How can we ensure smooth adoption?**
- Who are your power users we should involve early?
- Any specific concerns from the team about changing systems?
- Preferred training approach for your team?

## Quick Yes/No Confirmations

Please confirm:
- [ ] Customer-specific pricing is needed
- [ ] You need purchase order/requisition functionality  
- [ ] Quick order by SKU is used frequently
- [ ] Customers need to see their order history
- [ ] You want customers to track shipments
- [ ] B2B customers should see different products than others
- [ ] You need net terms/credit limits per customer
- [ ] Tax exemption handling is required

## Data for Accurate Proposal

Please provide if possible:
- Average number of orders per day/month
- Average order value (already noted ~$600)
- Peak order volume periods
- Number of active customers
- Number of SKUs typically ordered together

---

**Note**: These clarifications will ensure the requirements document accurately reflects your needs and the solution demonstration addresses your specific use cases.