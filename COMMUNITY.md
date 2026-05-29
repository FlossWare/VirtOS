# VirtOS Community

Welcome to the VirtOS community! This document provides guidance on how to participate, get help, and contribute to the project.

## Quick Links

- **Repository**: https://github.com/FlossWare/VirtOS
- **Issue Tracker**: https://github.com/FlossWare/VirtOS/issues
- **GitHub Discussions**: https://github.com/FlossWare/VirtOS/discussions *(to be enabled)*
- **Contributing Guide**: [CONTRIBUTING.md](CONTRIBUTING.md)
- **Code of Conduct**: [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)

## Getting Help

### Before Asking

1. **Check Documentation**:
   - [README.md](README.md) - Project overview
   - [docs/](docs/) - Comprehensive guides
   - [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - Common issues

2. **Search Existing Issues**:
   - Someone may have already reported your issue
   - Use GitHub issue search with relevant keywords

3. **Review CLAUDE.md**:
   - [CLAUDE.md](CLAUDE.md) - Project architecture and status
   - [docs/V1_0_ROADMAP.md](docs/V1_0_ROADMAP.md) - v1.0 timeline

### Where to Ask

#### GitHub Issues
**For**: Bug reports, feature requests, security issues

**Use when**:
- Something doesn't work as expected
- You want to propose a new feature
- You found a security vulnerability (report privately)

**Template**: Use issue templates in `.github/ISSUE_TEMPLATE/`

#### GitHub Discussions *(Coming Soon)*
**For**: Questions, ideas, general discussion

**Categories** (once enabled):
- 📣 **Announcements** - Release updates, important news
- 💬 **General** - General chat about VirtOS
- 💡 **Ideas** - Feature ideas and brainstorming
- ❓ **Q&A** - Questions and answers
- 🙏 **Show and Tell** - Share your VirtOS deployments
- 🚀 **Deployment Stories** - Production use cases
- 🛠️ **Development** - Contributor discussion

**Use when**:
- You have a question about using VirtOS
- You want to share your deployment
- You have an idea but aren't ready to file an issue
- You want to discuss implementation approaches

#### Discord *(Future)*
**For**: Real-time chat, quick questions

**Status**: Not yet set up (see Issue #101)

**Planned Channels**:
- #announcements - Release updates
- #general - General chat
- #support - User help
- #development - Contributor discussion
- #off-topic - Non-VirtOS chat

## Support Tiers

### Community Support (Free)
**Response Time**: Best effort (typically 1-7 days)

**Channels**:
- GitHub Issues
- GitHub Discussions
- Documentation

**Coverage**:
- Bug reports
- Feature requests
- General questions
- Documentation improvements

**Who Provides**:
- Project maintainers (volunteer time)
- Community contributors
- Other users

### Commercial Support *(Future)*
**Response Time**: SLA-based (4 hours - 2 business days)

**Status**: Not yet available (planned post-v1.0)

**Will Include**:
- Priority bug fixes
- Dedicated support engineer
- Custom feature development
- Training and onboarding
- Deployment assistance
- 24/7 emergency support (premium tier)

**Contact**: support@virtos.org *(not yet active)*

## How to Contribute

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

### Quick Start
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### High-Impact Contributions

**Runtime Testing** (CRITICAL):
- Test ISO on real hardware
- Report hardware compatibility
- Validate VM lifecycle
- See [TESTING_ROADMAP.md](docs/TESTING_ROADMAP.md)

**Backend Implementation**:
- Implement infrastructure script backends (Issue #14)
- 9 scripts need backends (virtos-auth, virtos-database, etc.)
- See [CLAUDE.md](CLAUDE.md) for details

**Documentation**:
- Write migration guides (Proxmox, VMware)
- Create video tutorials
- Improve troubleshooting guides
- Translate documentation

**Community Building**:
- Answer questions in Discussions
- Help new users
- Share your deployment stories
- Report bugs and test fixes

## Community Guidelines

### Code of Conduct
All community members must follow our [Code of Conduct](CODE_OF_CONDUCT.md).

**Summary**:
- Be respectful and inclusive
- No harassment or discrimination
- Constructive feedback only
- Assume good intentions

**Enforcement**: Violations can be reported via GitHub Issues or email to maintainers.

### Communication Standards

**Be Helpful**:
- Provide context and details
- Link to relevant documentation
- Share error messages and logs
- Describe what you've already tried

**Be Respectful**:
- Remember maintainers are volunteers
- Be patient waiting for responses
- Thank people for their help
- Give credit where due

**Be Clear**:
- Use descriptive titles
- Format code and logs properly
- Include environment details (OS, version)
- One issue per GitHub issue/discussion

### Issue Etiquette

**Good Issue**:
```markdown
Title: virtos-create-vm fails with "domain already exists" error

**Environment**:
- VirtOS version: 0.67
- Host OS: Fedora 38
- libvirt version: 9.0.0

**Steps to Reproduce**:
1. Run `virtos-create-vm test-vm`
2. VM created successfully
3. Run `virtos-create-vm test-vm` again
4. Error: "domain already exists"

**Expected**: Friendly error message suggesting to use a different name

**Actual**: Cryptic virsh error message

**Logs**:
```
ERROR: virsh error: domain 'test-vm' already exists
```

**What I've Tried**:
- Checked virtos-create-vm source code
- Looked for validation logic
- Found TODO comment for better error handling
```

**Bad Issue**:
```markdown
Title: doesn't work

it doesn't work help
```

## Governance

### Current Model
**Benevolent Dictator** (BDFL): Project maintainer(s)

**Decision Making**:
- Maintainers approve PRs
- Community input valued
- Major decisions discussed in Issues/Discussions
- Roadmap guided by community needs

### Future Model *(When Community Grows)*
**Technical Steering Committee** (TSC)
- 5-7 core contributors
- Vote on major architectural decisions
- Term-based membership
- Public meeting notes

**Contributor Ladder**:
1. **User** - Uses VirtOS
2. **Contributor** - 1+ merged PR
3. **Regular Contributor** - 5+ merged PRs
4. **Committer** - Triage issues, review PRs
5. **Maintainer** - Merge rights, release authority
6. **TSC Member** - Architectural decisions

## Recognition

### Contributors
All contributors are recognized in:
- Git commit history
- GitHub contributors page
- Release notes (for significant contributions)

### Hall of Fame *(Future)*
Outstanding contributors recognized with:
- Mention in README.md
- Blog post featuring their work
- Invitation to speak at community calls
- Early access to new features

## Community Calls *(Future)*

**Status**: Not yet scheduled (planned post-v1.0)

**Planned Format**:
- Monthly video calls
- Open agenda (submit topics in advance)
- Recorded and posted publicly
- Inclusive of all timezones (rotating times)

**Topics**:
- Roadmap updates
- Demo new features
- Community Q&A
- Contributor recognition

## Resources

### Documentation
- **User Guides**: [docs/](docs/)
- **Architecture**: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- **API Reference**: [docs/API.md](docs/API.md) *(coming soon)*
- **Roadmap**: [docs/V1_0_ROADMAP.md](docs/V1_0_ROADMAP.md)

### Development
- **Contributing**: [CONTRIBUTING.md](CONTRIBUTING.md)
- **Build System**: [BUILD.md](BUILD.md)
- **Testing**: [TESTING_ROADMAP.md](docs/TESTING_ROADMAP.md)
- **AI Development Guide**: [CLAUDE.md](CLAUDE.md)

### Project Management
- **Issue Tracker**: https://github.com/FlossWare/VirtOS/issues
- **Project Boards**: https://github.com/FlossWare/VirtOS/projects
- **Milestones**: https://github.com/FlossWare/VirtOS/milestones

## FAQ

### General

**Q: Is VirtOS production-ready?**  
A: Not yet. Core VM management works, but needs runtime testing (see [V1_0_ROADMAP.md](docs/V1_0_ROADMAP.md)). Estimated v1.0 release: Q3 2026.

**Q: What hypervisors does VirtOS support?**  
A: KVM/QEMU (primary), LXC (system containers), Docker/Podman/containerd (OCI containers).

**Q: How does VirtOS compare to Proxmox?**  
A: VirtOS is lighter weight (~100-400MB vs 1GB+ ISO), designed for minimal footprint. Proxmox is more mature and feature-rich. VirtOS is ideal for edge/embedded/home lab.

**Q: Can I migrate from Proxmox/VMware?**  
A: Migration guides are planned (Issue #133). Manual migration is possible today by exporting VMs and importing to VirtOS.

### Technical

**Q: What Linux distro is VirtOS based on?**  
A: Tiny Core Linux - an ultra-minimal distribution (11MB base).

**Q: Can I run VirtOS in a VM?**  
A: Yes, but you need nested virtualization enabled on the host.

**Q: What are the hardware requirements?**  
A: Minimum: x86_64 CPU with VT-x/AMD-V, 2GB RAM, 8GB storage. Recommended: 4+ cores, 8GB+ RAM, 50GB+ storage.

**Q: Does VirtOS support ARM?**  
A: Not currently. x86_64 only in v1.0. ARM support is a future consideration.

### Contributing

**Q: I found a bug. Should I file an issue or fix it myself?**  
A: Either! Filing an issue helps, but PRs are even better. If unsure how to fix, file an issue first.

**Q: I'm new to open source. How can I contribute?**  
A: Start with documentation improvements, test existing features, or help answer questions. Check issues labeled `good-first-issue`.

**Q: How long until my PR is reviewed?**  
A: Typically 1-7 days. Maintainers are volunteers, so please be patient. Ping the PR after 7 days if no response.

**Q: My PR was rejected. What should I do?**  
A: Read the feedback carefully. Maintainers explain why. You can revise and resubmit, or discuss in the PR comments.

### Licensing

**Q: What license is VirtOS?**  
A: GNU General Public License v3.0 (GPLv3). Changed from MIT in v0.67.

**Q: Can I use VirtOS commercially?**  
A: Yes! GPLv3 allows commercial use. You must distribute the source code if you distribute VirtOS.

**Q: Can I fork VirtOS and make it proprietary?**  
A: No. GPLv3 requires derivative works to also be GPLv3.

## Getting Started

### New Users
1. Read [README.md](README.md)
2. Check [docs/QUICK-START.md](docs/QUICK-START.md) *(if exists)*
3. Try building VirtOS locally (see [BUILD.md](BUILD.md))
4. Join GitHub Discussions *(once enabled)*
5. Report issues or ask questions

### New Contributors
1. Read [CONTRIBUTING.md](CONTRIBUTING.md)
2. Check [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
3. Look for `good-first-issue` labels
4. Fork, code, test, submit PR
5. Respond to review feedback

### Testers
1. See [TESTING_ROADMAP.md](docs/TESTING_ROADMAP.md)
2. Try ISO on real hardware (critical need!)
3. Report results in Issue #1 or #52
4. Help validate integration tests (Issue #103)

## Enabling GitHub Discussions

**Status**: Not yet enabled (requires repository admin)

**Steps for Repository Admin**:
1. Go to repository Settings
2. Scroll to "Features" section
3. Check "Discussions"
4. Click "Set up discussions"
5. Create initial categories:
   - 📣 Announcements (maintainers only can post)
   - 💬 General
   - 💡 Ideas
   - ❓ Q&A (enable answer marking)
   - 🙏 Show and Tell
   - 🚀 Deployment Stories
   - 🛠️ Development

**Initial Post** (suggested):
```markdown
Title: Welcome to VirtOS Discussions! 🎉

Welcome to the VirtOS community! This is a place to:

- Ask questions about using VirtOS
- Share your deployment stories
- Discuss ideas for new features
- Get help troubleshooting issues
- Connect with other VirtOS users

**New to VirtOS?** Start here:
- [README.md](https://github.com/FlossWare/VirtOS/blob/main/README.md)
- [Documentation](https://github.com/FlossWare/VirtOS/blob/main/docs/)
- [Contributing Guide](https://github.com/FlossWare/VirtOS/blob/main/CONTRIBUTING.md)

**Guidelines**:
- Be respectful (see our [Code of Conduct](https://github.com/FlossWare/VirtOS/blob/main/CODE_OF_CONDUCT.md))
- Search before posting
- Use appropriate categories
- Provide details (version, OS, logs)

**Need immediate help?** Check [COMMUNITY.md](https://github.com/FlossWare/VirtOS/blob/main/COMMUNITY.md) for support options.

Looking forward to building VirtOS together! 🚀
```

## Contact

- **GitHub Issues**: Bug reports, feature requests
- **GitHub Discussions**: Questions, ideas *(once enabled)*
- **Email**: *(not yet set up - use GitHub for now)*
- **Security Issues**: Report privately to repository maintainers

## Acknowledgments

VirtOS is built on the shoulders of giants:
- **Tiny Core Linux** - Minimal Linux distribution
- **libvirt/QEMU** - Virtualization infrastructure
- **LXC** - System containers
- **Docker/Podman** - OCI containers
- **All Contributors** - Thank you!

---

**Last Updated**: 2026-05-29  
**Version**: 0.67  
**Questions?** Open a GitHub Issue or Discussion
