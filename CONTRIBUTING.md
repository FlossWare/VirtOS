# Contributing to FlossWare VirtOS

Thank you for considering contributing! This project aims to create a minimal, efficient virtualization platform based on Tiny Core Linux.

## Project Philosophy

- **Minimal**: Only include what's necessary
- **Modular**: Use Tiny Core's extension system
- **Flexible**: Support multiple virtualization technologies
- **Open**: Community-driven development

## How to Contribute

### Reporting Issues

- Check existing issues first
- Provide system info (CPU, RAM, Tiny Core version)
- Include steps to reproduce
- Share relevant logs/error messages

### Suggesting Features

- Align with minimal/modular philosophy
- Consider if it belongs in core or as optional extension
- Explain use case and benefits
- Check roadmap first (docs/ROADMAP.md)

### Code Contributions

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/my-feature
   ```

3. **Make your changes**
   - Follow existing code style
   - Test thoroughly
   - Update documentation

4. **Commit with clear messages**
   ```bash
   git commit -m "Add support for XYZ virtualization"
   ```

5. **Push and create pull request**
   ```bash
   git push origin feature/my-feature
   ```

### Building Custom Packages

If you're adding a new TCZ extension:

1. Place build scripts in `packages/`
2. Document dependencies
3. Include .tcz.info file
4. Test installation and functionality
5. Add to appropriate phase in ROADMAP.md

### Documentation

- Keep docs concise and clear
- Use examples liberally
- Update relevant .md files with changes
- Spell check and proofread

## Development Setup

See [docs/GETTING-STARTED.md](docs/GETTING-STARTED.md) for build environment setup.

## Testing

Before submitting:

1. Build ISO successfully
2. Test boot in QEMU/KVM
3. Verify core functionality
4. Check no regressions
5. Test on real hardware if possible

## Areas Needing Help

Current priorities (see ROADMAP.md):

**Core System**:
- [ ] Custom kernel configuration optimization
- [ ] TCZ package building automation
- [ ] Build script improvements
- [ ] Testing on various hardware

**Advanced Features**:
- [ ] Web UI integration (Cockpit/Portainer)
- [ ] GPU passthrough support
- [ ] USB passthrough
- [ ] Live VM migration
- [ ] High availability implementation
- [ ] Advanced networking (OVS, VLANs)

**Documentation**:
- [ ] Video tutorials
- [ ] More examples and use cases
- [ ] Troubleshooting guides
- [ ] Performance tuning guides
- [ ] Translation to other languages

**Testing**:
- [ ] Automated testing
- [ ] Integration tests
- [ ] Performance benchmarks
- [ ] Hardware compatibility list

**Community**:
- [ ] Sample configurations
- [ ] Template library
- [ ] Blog posts / articles
- [ ] Community support

## Code Style

- Shell scripts: Follow existing style, use shellcheck
- Comments: Only when necessary (what/why, not how)
- Naming: Descriptive, lowercase with hyphens
- Error handling: Always check exit codes

## Communication

- GitHub Issues: Bug reports, feature requests
- GitHub Discussions: Questions, ideas, help
- Pull Requests: Code contributions

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (TBD - to be determined).

## Questions?

Open an issue or discussion - we're happy to help!
