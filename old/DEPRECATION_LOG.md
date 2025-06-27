# Deprecation and Archive Log

This directory contains files that have been moved, deprecated, or archived during the evolution of LinkWatcher.

## 📁 Files in this Directory

### `README_LINK_WATCHER.md`
- **Original location**: `/README_LINK_WATCHER.md` (project root)
- **Moved on**: 2024-12-19
- **Reason**: Replaced with new modular documentation structure
- **Status**: ✅ **ARCHIVED** - Preserved for reference
- **Replacement**:
  - Main documentation: `/README.md`
  - Architecture details: `/RESTRUCTURE_README.md`
  - Setup guide: `/MULTI_PROJECT_SETUP.md`
  - Detailed docs: `/docs/` directory

### `link_watcher_old.py`
- **Original name**: `link_watcher.py`
- **Moved on**: 2024-12-19
- **Reason**: Replaced with modular implementation
- **Status**: ✅ **FUNCTIONAL** - Still works, backward compatible
- **Replacement**: `/link_watcher_new.py`
- **Notes**:
  - Fully functional legacy implementation
  - Use for backward compatibility
  - Gradually migrate to new version

## 🔄 Migration Status

### Documentation Migration
- ✅ **README_LINK_WATCHER.md** → Multiple focused documents
  - Content preserved and expanded
  - Better organization and navigation
  - More comprehensive coverage

### Code Migration
- ✅ **link_watcher.py** → Modular architecture
  - Same functionality maintained
  - Better performance and maintainability
  - Extensible plugin system

## 📋 Usage Guidelines

### When to Use Files in This Directory

#### Use `link_watcher_old.py` when:
- ✅ You need proven stability
- ✅ You're in the middle of a critical project
- ✅ You want to test the new version alongside the old
- ✅ You encounter issues with the new version

#### Use `README_LINK_WATCHER.md` when:
- ✅ You need to reference original documentation
- ✅ You're comparing old vs new features
- ✅ You're writing migration documentation
- ✅ You need historical context

### When NOT to Use These Files

#### Don't use for new projects:
- ❌ New installations should use the current version
- ❌ New documentation should reference current docs
- ❌ New features are only in the current version

## 🚨 Important Notes

### Maintenance Status
- **link_watcher_old.py**:
  - ⚠️ **Maintenance mode** - Critical bugs only
  - ⚠️ **No new features** will be added
  - ⚠️ **Will be removed** in v3.0 (with advance notice)

- **README_LINK_WATCHER.md**:
  - 📚 **Archive only** - No updates
  - 📚 **Historical reference** - Content frozen
  - 📚 **Permanent archive** - Will not be removed

### Support Policy
- **Current version**: Full support and active development
- **Legacy files**: Critical bug fixes only
- **Archived docs**: No updates, reference only

## 🔮 Future Plans

### v2.x Series
- Legacy files remain functional
- Gradual migration encouraged
- Full backward compatibility

### v3.0 (Future)
- **Planned**: Remove `link_watcher_old.py`
- **Timeline**: TBD (with 6+ months notice)
- **Migration**: Comprehensive guide will be provided
- **Archive docs**: Will remain permanently

## 📞 Support

If you need help with:
- **Legacy files**: Check original documentation first
- **Migration**: See `/docs/migration-guide.md`
- **Issues**: Report in main project, specify version

---

**This directory preserves LinkWatcher's evolution while maintaining backward compatibility** 📚✨
