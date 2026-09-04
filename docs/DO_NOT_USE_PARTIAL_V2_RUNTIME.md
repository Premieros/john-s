# Partial V2 runtime policy

`V2PosPage`, `V2ShiftsPage`, `V2HomePage`, and `V2AppShell` are retained temporarily for source-history compatibility, but production routing must not import or render them. The canonical entry is `V2GatewayPage`, which links to the tested production workspaces.

Do not restore a partial V2 workspace to routing without proving Backend + Permission + Branch/RLS + Integration + Browser coverage for the entire operational cycle.
