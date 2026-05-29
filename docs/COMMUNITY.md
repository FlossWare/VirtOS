# VirtOS Community Guide

**Last Updated**: 2026-05-29  
**Status**: Community Infrastructure Setup Guide  
**Related Issue**: [#101](https://github.com/FlossWare/VirtOS/issues/101)

---

## Overview

This document outlines VirtOS's community infrastructure and how to participate in the project.

## Communication Channels

### GitHub Discussions (Recommended)

**Primary platform for community interaction and support**

**Setup Instructions** (For Repository Admins):

1. Go to <https://github.com/FlossWare/VirtOS/settings>
2. Scroll to "Features" section
3. Check "Discussions"
4. Click "Set up Discussions"
5. Create the following categories:

#### Recommended Discussion Categories

| Category | Purpose | Format |
|----------|---------|--------|
| 📢 **Announcements** | Release notes, major updates, important news | Announcement |
| 💬 **General** | General VirtOS discussion | Open-ended discussion |
| 💡 **Ideas** | Feature requests, enhancement proposals | Open-ended discussion |
| ❓ **Q&A** | User questions and support requests | Q&A |
| 🙌 **Show and Tell** | Share your VirtOS setups, deployments, use cases | Open-ended discussion |
| 🛠️ **Development** | Contributor discussion, development topics | Open-ended discussion |
| 🐛 **Troubleshooting** | Debug and resolve issues together | Q&A |

#### Category Configuration

**Announcements**:

- **Emoji**: 📢
- **Description**: "Official announcements from VirtOS maintainers"
- **Format**: Announcement (maintainers only)
- **Initial Posts**: Pin release notes, roadmap updates

**General**:

- **Emoji**: 💬
- **Description**: "General discussion about VirtOS"
- **Format**: Open-ended discussion
- **Initial Posts**: Welcome post, community guidelines

**Ideas**:

- **Emoji**: 💡
- **Description**: "Propose new features and enhancements"
- **Format**: Open-ended discussion
- **Initial Posts**: How to submit ideas, feature request template

**Q&A**:

- **Emoji**: ❓
- **Description**: "Ask questions and get help from the community"
- **Format**: Question / Answer
- **Initial Posts**: Common questions, where to find documentation

**Show and Tell**:

- **Emoji**: 🙌
- **Description**: "Share your VirtOS deployments and use cases"
- **Format**: Open-ended discussion
- **Initial Posts**: Example setups, deployment stories

**Development**:

- **Emoji**: 🛠️
- **Description**: "Developer discussions and contribution topics"
- **Format**: Open-ended discussion
- **Initial Posts**: How to contribute, development setup guide

**Troubleshooting**:

- **Emoji**: 🐛
- **Description**: "Get help debugging issues and solving problems"
- **Format**: Question / Answer
- **Initial Posts**: Troubleshooting checklist, common issues

### GitHub Issues

**For bug reports and tracked work**

- **Bug Reports**: Use bug report template
- **Feature Requests**: Submit as an issue or start in Discussions/Ideas first
- **Security Issues**: Report privately to maintainers (see SECURITY.md)

**When to use Issues vs Discussions**:

- **Use Issues**: Confirmed bugs, tracked features, assigned work
- **Use Discussions**: Questions, ideas, general help, community chat

### Pull Requests

**For code contributions**

See [CONTRIBUTING.md](../CONTRIBUTING.md) for detailed guidelines.

## Community Guidelines

### Code of Conduct

VirtOS follows the [Contributor Covenant Code of Conduct](../CODE_OF_CONDUCT.md).

**In summary**:

- ✅ Be respectful and inclusive
- ✅ Welcome newcomers
- ✅ Provide constructive feedback
- ✅ Focus on what's best for the community
- ❌ No harassment, discrimination, or trolling
- ❌ No spam or off-topic content

### Asking Questions

**Before asking**:

1. Search existing discussions and issues
2. Check the [documentation](../docs/)
3. Review [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

**When asking**:

- Provide context (VirtOS version, OS, hardware)
- Include error messages and logs
- Describe what you've already tried
- Use code blocks for terminal output

**Example good question**:

```markdown
## VM fails to start with "permission denied" error

**Environment**:
- VirtOS version: 0.1
- Host OS: Fedora 44
- Hardware: Intel i7, 16GB RAM, VT-x enabled

**Steps to reproduce**:
1. `virtos-create-vm test-vm --memory 2048 --disk 20`
2. `virtos-vm-start test-vm`

**Error**:
```

ERROR: permission denied accessing /var/lib/libvirt/images/test-vm.qcow2

```

**What I've tried**:
- Checked file permissions: `-rw-r--r-- qemu:qemu`
- User is in `libvirt` group
- Restarted libvirtd service

Any ideas what's wrong?
```

### Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for:

- Development setup
- Coding standards
- Pull request process
- Testing requirements

### Support Tiers

#### Community Support (Free)

- GitHub Discussions
- GitHub Issues
- Community-driven help
- Best-effort response time

#### Commercial Support (Future)

*Not yet available - under consideration*

Potential offerings:

- Priority support
- Custom feature development
- Training and consultation
- SLA guarantees
- Professional services

**Interested in commercial support?** Open a discussion in the **Ideas** category.

## Recognition

### Contributors

All contributors are recognized in:

- Repository [contributors page](https://github.com/FlossWare/VirtOS/graphs/contributors)
- Release notes (for significant contributions)
- Git commit history (Co-Authored-By tags)

### Hall of Fame

**Top Contributors** (by impact):

- *To be added as community grows*

**Special Thanks**:

- Tiny Core Linux project
- platform-java contributors
- All beta testers and early adopters

## Events and Meetings

### Community Calls (Future)

*Not yet scheduled - depends on community growth*

Potential format:

- Monthly video calls
- Agenda posted in Discussions
- Recorded and published
- Open to all community members

### Conferences and Meetups

**VirtOS Presence**:

- *To be announced as project matures*

**Want to present about VirtOS?** Let us know in Discussions!

## Resources

### Official Resources

- **Repository**: <https://github.com/FlossWare/VirtOS>
- **Documentation**: <https://github.com/FlossWare/VirtOS/tree/main/docs>
- **Issue Tracker**: <https://github.com/FlossWare/VirtOS/issues>
- **Package Registry**: <https://packagecloud.io/flossware/virtos>

### External Resources

- **Tiny Core Linux**: <https://tinycorelinux.net/>
- **platform-java**: <https://github.com/FlossWare/platform-java>
- **Libvirt Documentation**: <https://libvirt.org/docs.html>
- **QEMU Documentation**: <https://www.qemu.org/documentation/>

## FAQ

### General Questions

**Q: Is VirtOS ready for production?**  
A: Not yet. VirtOS is in alpha/prototype phase. Core VM management is functional but needs more testing. See [STATUS.md](../STATUS.md) for current state.

**Q: How does VirtOS compare to Proxmox/ESXi/etc?**  
A: See [COMPARISON.md](COMPARISON.md) for detailed comparisons.

**Q: Can I use VirtOS commercially?**  
A: Yes! VirtOS is GPL-3.0 licensed. Use it for any purpose, including commercial.

### Technical Questions

**Q: What hardware does VirtOS support?**  
A: Currently x86_64 with VT-x or AMD-V virtualization extensions. See [INSTALLATION.md](INSTALLATION.md) for requirements.

**Q: Can VirtOS run containers and VMs together?**  
A: Yes! Via the platform-java integration. See [PLATFORM-JAVA_INTEGRATION.md](PLATFORM-JAVA_INTEGRATION.md).

**Q: Does VirtOS have a web UI?**  
A: Yes! VirtOS includes a Cockpit module. See [WEB-UI.md](WEB-UI.md) for details.

### Contributing Questions

**Q: How can I contribute without coding?**  
A: Documentation, testing, bug reports, community support, and feedback are all valuable contributions!

**Q: I found a typo in the docs. Should I open an issue?**  
A: Small fixes can go directly to a PR. See [CONTRIBUTING.md](../CONTRIBUTING.md).

**Q: I have an idea for a new feature. What should I do?**  
A: Start a discussion in the **Ideas** category first. This helps gauge interest and refine the proposal before implementation.

## Governance

### Project Maintainers

**Current Maintainers**:

- See [GitHub org members](https://github.com/orgs/FlossWare/people)

**Maintainer Responsibilities**:

- Review and merge pull requests
- Triage issues
- Make architecture decisions
- Release management
- Community moderation

### Decision Making

**Minor Decisions** (bug fixes, small features):

- Maintainer approval via PR review

**Major Decisions** (architecture changes, breaking changes):

- Proposal in Discussions
- Community feedback period (1-2 weeks)
- Maintainer consensus
- Decision documented in docs/

### Becoming a Maintainer

*Process to be formalized as project grows*

Potential criteria:

- Consistent high-quality contributions
- Understanding of project architecture
- Community engagement
- Trustworthiness

## Roadmap Influence

The community influences VirtOS development through:

1. **Discussions** - Feature ideas and feedback
2. **Issues** - Bug reports and feature requests
3. **Pull Requests** - Direct code contributions
4. **Voting** - 👍 reactions on issues/discussions

See [ROADMAP.md](ROADMAP.md) for current development priorities.

## Getting Started

**New to VirtOS?**

1. **Read**: [README.md](../README.md) and [GETTING-STARTED.md](GETTING-STARTED.md)
2. **Try**: Boot the ISO or install packages
3. **Ask**: Join Discussions if you have questions
4. **Contribute**: See [CONTRIBUTING.md](../CONTRIBUTING.md)
5. **Share**: Post your experience in **Show and Tell**

**Welcome to the VirtOS community!** 🎉

---

## Next Steps for Community Infrastructure

**Immediate** (Requires admin access):

- [ ] Enable GitHub Discussions
- [ ] Create discussion categories
- [ ] Pin welcome post
- [ ] Migrate relevant issues to discussions

**Short-term** (1-2 months):

- [ ] Create community guidelines post
- [ ] Set up automated moderation
- [ ] Create discussion templates
- [ ] Seed categories with content

**Long-term** (3-6 months):

- [ ] Evaluate need for Discord/Slack
- [ ] Consider mailing list
- [ ] Plan community calls
- [ ] Formalize governance model

---

**Document Version**: 1.0  
**Author**: VirtOS Team  
**License**: Same as VirtOS project (GPL-3.0)
