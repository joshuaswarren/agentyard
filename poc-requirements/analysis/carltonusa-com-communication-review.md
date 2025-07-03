# Communication Review: CarltonUSA.com

**Reviewed By**: Client Communication Specialist
**Date**: 2025-07-03
**Confidence Level**: Medium-High

## Stakeholder Map

```mermaid
graph TD
    DM[Decision Maker: Rick Carlton - Owner]
    TC[Technical Contact: Jennifer Carlton - Marketing/Graphics]
    FM[Finance: Accounting Manager]
    OM[Operations: Purchasing Ops Manager]
    SM[Sales: Sales Manager]
    EU[End Users: CSRs on phones]
    SI[Silent Influencer: Ability Commerce]
    
    DM --> |approves| Budget
    DM --> |manages| Vendor Relations
    TC --> |validates| Marketing Tech
    TC --> |19 years tenure| Trust
    FM --> |controls| Financial Integration
    OM --> |manages| Fulfillment Process
    SM --> |drives| Sales Requirements
    EU --> |experiences| Daily Pain Points
    SI -.-> |creates friction| DM
```

## Communication Insights

### 🎯 Crystal Clear Requirements
Requirements with high confidence:
1. **Real-time shipping calculation**
   - Quote: 【Rick: "Website gave me $15 in shipping... CCS converted the shipping to actual and it became sixty seven dollars"】
   - Success metric: 100% accurate shipping quotes
   - Priority: Explicitly stated as deal-breaker

2. **B2B company account structure**
   - Quote: 【Rick: "We have a buyer who's the person buying something. We have the payer... and the ship to."】
   - Success metric: Support separate buyer/payer/ship-to entities
   - Priority: Critical - fundamental to business model

3. **Multiple product customizations affecting price**
   - Quote: 【Rick: "Many of our products have at least four to five points of customization and those customizations affect the price"】
   - Success metric: Support 5+ customization options with dynamic pricing
   - Priority: Critical - 70% of business is custom

### 🤔 Needs Clarification
Requirements needing follow-up:
1. **Virtual catalog functionality**
   - What they said: 【Website analysis noted "Virtual catalogs" feature】
   - What's unclear: Is this PDF generation or interactive online experience?
   - Suggested question: "Can you walk me through how customers use your virtual catalogs today?"

2. **Sample request workflow**
   - What they said: 【Website shows "Request samples" feature】
   - What's unclear: Integration with fulfillment, approval process, cost handling
   - Suggested question: "What's the typical sample request process from request to delivery?"

3. **EDI/ACH payment processing**
   - What they said: 【Rick: "A big chunk pay with EDI/ACH"】
   - What's unclear: Volume, specific requirements, integration needs
   - Suggested question: "What percentage of orders use EDI/ACH vs credit cards?"

4. **Production item management**
   - What they said: 【Rick: "Ability does not understand the concept of a production item"】
   - What's unclear: Lead times, status tracking, customer communication
   - Suggested question: "How do you currently track and communicate production status to customers?"

### 🔍 Reading Between the Lines
Inferred from context:
1. **CSR productivity is suffering**
   - Clues: Multiple workarounds, manual credit application, system limitations
   - Confidence: 90%
   - Validation needed: Time study of current order process

2. **Trust issues with vendors**
   - Clues: Rick's hesitation about Adobe, Groupon story, "marriage" analogy
   - Confidence: 85%
   - Validation needed: Reference checks will be critical

3. **Cash flow sensitivity**
   - Clues: Emphasis on implementation budget, ROI focus, small business comments
   - Confidence: 80%
   - Validation needed: Discuss payment terms and phased approach

## Emotional Landscape

### Pain Points (Urgency Indicators)
| Pain Point | Intensity | Business Impact | Quote |
|------------|-----------|-----------------|--------|
| Vendor lock-in frustration | 🔥🔥🔥 | Can't optimize or get help | 【"We're essentially limited"】 |
| Lost customers | 🔥🔥🔥 | Direct revenue loss | 【"We have lost customers over it"】 |
| Operational inefficiency | 🔥🔥 | Hidden costs, morale | 【"We spend more time running our systems"】 |
| No profitability online | 🔥🔥 | Questioning investment | 【"We are not making money"】 |

### Success Vision
What success looks like to them:
- "We were profitable. We were just small" - They want profitable growth, not just growth
- "We take care of our folks" - Customer service excellence is core value
- "We don't have to make workarounds" - System that works as promised
- Local partner who understands B2B complexity

### Hidden Concerns
Potential worries not explicitly stated:
- Fear of another bad vendor relationship ("It's like some exes")
- Concern about Adobe's enterprise focus vs their small business needs
- Worry about staff adoption and training (CSRs, managers)
- Cash flow impact during parallel system operation

## Business Context Analysis

### Competitive Pressure
- Mentioned competitors: Uline (giant), Labelmaster ($1.3B conglomerate), Sign Warehouse (low price)
- Pressure points: Can't compete on price, must excel on service and customization
- Urgency driver: Losing customers to poor website experience while competitors improve

### Growth Trajectory
- Current state: $17K/month online (tiny fraction of $3.5M total)
- Growth target: Turn online channel profitable, capture more of TAM
- Scaling concerns: System must handle complexity without adding headcount

### Budget Psychology
- Stated budget: $40-60K implementation
- Budget indicators: Willing to pay current $27K/month for better ROI
- Value focus: Both cost-saving (reduce workarounds) AND revenue-growth
- Decision timeline: 3-4 months (not rushed but committed)

## Risk Communication

### 🚨 Red Flags
1. **Current vendor is also Dynamics reseller**
   - Indicator: Triple vendor lock-in situation
   - Impact if ignored: Difficult extraction, data hostage situation
   - Mitigation: Ensure data ownership and extraction plan upfront

2. **Minimal online revenue vs. investment**
   - Indicator: $17K revenue vs $27K spend
   - Impact if ignored: Another failed investment
   - Mitigation: Phased approach with quick wins

### ⚠️ Yellow Flags  
1. **Many stakeholders not yet engaged**
   - Why it matters: Buy-in needed from ops, finance, sales
   - How to address: Include in next demo, get their specific needs

2. **Parallel system operation planned**
   - Why it matters: Double costs, data sync challenges
   - How to address: Clear migration timeline and milestones

## Recommended Follow-ups

### Immediate Clarifications Needed
Email template:
```
Subject: Quick clarification on Carlton's unique requirements

Hi Rick,

Following up on our discussion about your B2B platform needs, I wanted to clarify a few specifics to ensure our proposal hits the mark:

1. When you mentioned "virtual catalogs", are these:
   a) PDF catalogs generated from your product data
   b) Interactive online catalog experiences
   c) Both?

2. Regarding the production items that are custom-made, what's the typical timeline from order to delivery? How do you currently communicate status updates to customers?

3. For the EDI/ACH payments, roughly what percentage of your orders use this vs. credit cards? This helps us prioritize the payment integrations.

4. You mentioned one buyer ordering for 150 locations. Is it common to need to:
   a) Split quantities across locations
   b) Set different delivery dates per location
   c) Track delivery confirmations separately

This will help ensure we demonstrate exactly how Adobe Commerce handles your specific scenarios.

Best regards,
[Name]
```

### Discovery Questions for Next Meeting
1. **Business Process**: "Walk me through a typical custom order from quote to delivery - who touches it and when?"
2. **Technical Constraint**: "What data do you need to pass to Dynamics, and how often?"  
3. **Success Metric**: "If we could fix just three things, what would make the biggest impact on your daily operations?"

## Confidence Score

Overall requirements confidence: 7.5/10

Breakdown:
- Functional requirements: 8/10 (clear on most, some gaps)
- Technical requirements: 7/10 (integrations need detail)
- Business goals: 9/10 (very clear on pain and vision)
- Success criteria: 6/10 (need specific metrics)

## Next Steps

- [ ] Send clarification email within 24 hours
- [ ] Schedule expanded demo with all stakeholders
- [ ] Research safety/compliance industry requirements
- [ ] Get Ability Commerce extraction plan
- [ ] Validate CSR workflow assumptions