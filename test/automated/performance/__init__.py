"""
Performance Tests for LinkWatcher

This package contains performance and scalability tests to ensure LinkWatcher
handles large projects and stress scenarios effectively.

Test files are organized by the 4-level performance taxonomy:
- level1-component/test_component_benchmarks.py: single-subsystem benchmarks (BM-001/002/004/007/008)
- level2-operation/test_operation_benchmarks.py: end-to-end operation benchmarks (BM-003/005/006)
- level3-scale/test_large_projects.py: large-project scale tests (PH-001..006)
- level4-resource/test_resource_bounds.py: resource-bound tests (PH-007 memory, PH-008 CPU)

Shared helpers (benchmark file generation, service warmup) are factory fixtures in
performance/conftest.py.
"""
