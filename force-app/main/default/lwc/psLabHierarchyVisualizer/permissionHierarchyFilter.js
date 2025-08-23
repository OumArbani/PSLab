import {deepClone} from "c/psLabCoreUtils";

export class PermissionHierarchyFilter {
    filter(hierarchyData, detectedPermissions, payload) {
        const highlightedIds = new Set();
        if (!hierarchyData || !detectedPermissions || detectedPermissions.length === 0) {
            return {filteredData: null, highlightedIds};
        }

        const filteredRoot = this._filterHierarchy(
            hierarchyData,
            detectedPermissions,
            payload,
            highlightedIds
        );

        return {filteredData: filteredRoot, highlightedIds};
    }

    _filterHierarchy(hierarchyData, detectedPermissions, payload, highlightedIds) {
        const filteredRoot = deepClone(hierarchyData);
        filteredRoot.children = [];
        const originalRootChildren = hierarchyData.children || [];

        const groupsBranch = originalRootChildren.find(b => b.name === 'Permission Set Groups');
        const standaloneBranch = originalRootChildren.find(b => b.name === 'Standalone Permission Sets');

        const filterType = payload?.permissionType;

        if (filterType === 'PSG') {
            if (groupsBranch) {
                const filtered = this._filterGroupsBranch(deepClone(groupsBranch), detectedPermissions, payload, highlightedIds);
                if (filtered) {
                    filteredRoot.children.push(filtered);
                }
            }
        }
        else {
            if (groupsBranch) {
                const filtered = this._filterGroupsBranch(deepClone(groupsBranch), detectedPermissions, payload, highlightedIds);
                if (filtered) {
                    filteredRoot.children.push(filtered);
                }
            }
            if (standaloneBranch) {
                const filtered = this._filterStandaloneBranch(deepClone(standaloneBranch), detectedPermissions, payload, highlightedIds);
                if (filtered) {
                    filteredRoot.children.push(filtered);
                }
            }
        }

        return (filteredRoot.children.length > 0) ? filteredRoot : null;
    }

    _filterGroupsBranch(branch, detectedPermissions, payload, highlightedIds) {
        const originalGroups = branch.children || [];
        let groupsToCheck = originalGroups;
        const allDetectedIds = this.collectIds(detectedPermissions);

        if (payload?.permissionType === 'PSG' && payload.permissionsAPINames) {
            const targetGroupNames = payload.permissionsAPINames.split(',').map(name => name.trim());
            groupsToCheck = originalGroups.filter(g => targetGroupNames.includes(g.name));
        }

        const filteredGroups = [];
        for (const group of groupsToCheck) {
            const matchingPsChildren = (group.children || []).filter(ps => allDetectedIds.has(ps.permissionSetId));

            if (matchingPsChildren.length > 0) {
                const filteredGroup = deepClone(group);
                filteredGroup.children = deepClone(matchingPsChildren);
                filteredGroups.push(filteredGroup);

                highlightedIds.add(group.permissionSetId);
                matchingPsChildren.forEach(ps => highlightedIds.add(ps.permissionSetId));
            }
        }

        if (filteredGroups.length > 0) {
            branch.children = filteredGroups;
            return branch;
        }
        return null;
    }

    _filterStandaloneBranch(branch, detectedPermissions, payload, highlightedIds) {
        const originalStandaloneSets = branch.children || [];
        let setsToCheck = originalStandaloneSets;

        if (payload?.permissionType === 'PS' && payload.permissionsAPINames) {
            const targetPsNames = payload.permissionsAPINames.split(',').map(name => name.trim());
            setsToCheck = originalStandaloneSets.filter(ps => targetPsNames.includes(ps.name));
        }

        const filteredStandaloneSets = [];
        for (const ps of setsToCheck) {
            const detectedInfo = this.findPermission(detectedPermissions, ps.permissionSetId);

            if (ps.permissionSetId.startsWith('0PS') && detectedInfo && (!detectedInfo.includedIn || detectedInfo.includedIn.length === 0)) {
                filteredStandaloneSets.push(deepClone(ps));
                highlightedIds.add(ps.permissionSetId);
            }
        }

        if (filteredStandaloneSets.length > 0) {
            branch.children = filteredStandaloneSets;
            return branch;
        }
        return null;
    }

    collectIds(nodeOrArray, ids = new Set()) {
        if (Array.isArray(nodeOrArray)) {
            for (const item of nodeOrArray) {
                this.collectIds(item, ids);
            }
        } else if (nodeOrArray && typeof nodeOrArray === 'object') {
            if (nodeOrArray.permissionSetId) {
                ids.add(nodeOrArray.permissionSetId);
            }

            if (nodeOrArray.children && Array.isArray(nodeOrArray.children)) {
                for (const child of nodeOrArray.children) {
                    this.collectIds(child, ids);
                }
            }
        }
        return ids;
    }

    findPermission(data, id) {
        if (!data) {
            return null;
        }

        if (Array.isArray(data)) {
            for (const item of data) {
                // Search each item in the array recursively.
                const found = this._findRecursive(item, id);
                if (found) {
                    return found;
                }
            }
        }

        else if (typeof data === 'object') {
            return this._findRecursive(data, id);
        }

        return null;
    }

    _findRecursive(node, id) {
        if (!node) {
            return null;
        }

        if (node.permissionSetId === id) {
            return node;
        }

        if (node.children && Array.isArray(node.children)) {
            for (const child of node.children) {
                const found = this._findRecursive(child, id);
                if (found) {
                    return found;
                }
            }
        }
        return null;
    }
}