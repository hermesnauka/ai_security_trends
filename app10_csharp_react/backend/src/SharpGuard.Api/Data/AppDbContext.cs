using Microsoft.EntityFrameworkCore;
using SharpGuard.Api.Entities;

namespace SharpGuard.Api.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<Framework> Frameworks => Set<Framework>();
    public DbSet<Threat> Threats => Set<Threat>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Framework>(e =>
        {
            e.ToTable("framework");
            e.HasKey(f => f.Id);
            e.Property(f => f.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(f => f.Code).HasColumnName("code").HasMaxLength(64).IsRequired();
            e.HasIndex(f => f.Code).IsUnique();
            e.Property(f => f.Name).HasColumnName("name").IsRequired();
            e.Property(f => f.Version).HasColumnName("version").HasMaxLength(32).IsRequired();
            e.Property(f => f.Description).HasColumnName("description");
            e.Property(f => f.ReferenceUrl).HasColumnName("reference_url").HasMaxLength(512);
        });

        modelBuilder.Entity<Threat>(e =>
        {
            e.ToTable("threat");
            e.HasKey(t => t.Id);
            e.Property(t => t.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(t => t.FrameworkId).HasColumnName("framework_id");
            e.HasOne(t => t.Framework)
                .WithMany(f => f.Threats)
                .HasForeignKey(t => t.FrameworkId)
                .OnDelete(DeleteBehavior.Restrict);

            e.Property(t => t.Code).HasColumnName("code").HasMaxLength(64).IsRequired();
            e.Property(t => t.Title).HasColumnName("title").IsRequired();
            e.Property(t => t.Severity)
                .HasColumnName("severity")
                .HasMaxLength(16)
                .HasConversion<string>()
                .IsRequired();
            e.Property(t => t.Category).HasColumnName("category").HasMaxLength(128);
            e.Property(t => t.Description).HasColumnName("description");
            e.Property(t => t.AttackVector).HasColumnName("attack_vector");
            e.Property(t => t.AttackSurface).HasColumnName("attack_surface");

            // Comma-joined TEXT columns, mapped as raw strings on purpose -
            // see the comment on Threat.Stride for why. Same deliberate
            // Phase-1 shortcut as app01's StringListConverter/StrideSetConverter.
            e.Property(t => t.Stride).HasColumnName("stride").HasMaxLength(32);
            e.Property(t => t.Tags).HasColumnName("tags");
            e.Property(t => t.CveReferences).HasColumnName("cve_references");

            e.HasIndex(t => t.FrameworkId);
            e.HasIndex(t => t.Severity);
            e.HasIndex(t => t.Category);
            e.HasIndex(t => new { t.FrameworkId, t.Code }).IsUnique();
        });
    }
}
