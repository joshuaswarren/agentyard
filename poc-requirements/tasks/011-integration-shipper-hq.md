# Task 011: Shipper HQ Integration

## Description
Implement Shipper HQ integration for complex shipping calculations including LTL freight, drop-shipping logic, dimensional weight calculations, and multi-warehouse shipping scenarios.

## Requirements Reference
- LTL freight calculations
- Drop-ship vendor routing
- Dimensional weight pricing
- Multi-warehouse shipping
- Hazmat shipping restrictions
- Real-time rate shopping

## Acceptance Criteria
- [ ] Shipper HQ extension installed and configured
- [ ] LTL freight carriers configured
- [ ] Drop-ship rules implemented
- [ ] Dimensional weight calculations accurate
- [ ] Warehouse routing logic working
- [ ] Hazmat restrictions enforced
- [ ] Rate shopping displaying correctly
- [ ] Checkout performance <3s with rate calls

## Technical Notes
- Use Shipper HQ official extension
- Configure carrier accounts
- Set up dimensional attributes on products
- Implement caching for rate responses
- Create fallback shipping methods
- Monitor API performance

## Effort Estimate
**40 hours** (5 days)

## Dependencies
- Shipper HQ account setup
- Carrier account credentials
- Product dimensional data
- Warehouse locations defined

## Priority Level
**High** - Critical for accurate shipping costs

## Risk Factors
- API rate limits during high traffic
- Complex rule configuration
- Carrier API reliability
- Checkout performance impact