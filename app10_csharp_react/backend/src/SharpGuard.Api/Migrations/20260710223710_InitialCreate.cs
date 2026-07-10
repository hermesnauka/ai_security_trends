using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SharpGuard.Api.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "framework",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    code = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    name = table.Column<string>(type: "text", nullable: false),
                    version = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    description = table.Column<string>(type: "text", nullable: true),
                    reference_url = table.Column<string>(type: "character varying(512)", maxLength: 512, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_framework", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "threat",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    framework_id = table.Column<Guid>(type: "uuid", nullable: false),
                    code = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    title = table.Column<string>(type: "text", nullable: false),
                    severity = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    category = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: true),
                    description = table.Column<string>(type: "text", nullable: true),
                    attack_vector = table.Column<string>(type: "text", nullable: true),
                    attack_surface = table.Column<string>(type: "text", nullable: true),
                    stride = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: true),
                    cve_references = table.Column<string>(type: "text", nullable: true),
                    tags = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_threat", x => x.id);
                    table.ForeignKey(
                        name: "FK_threat_framework_framework_id",
                        column: x => x.framework_id,
                        principalTable: "framework",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_framework_code",
                table: "framework",
                column: "code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_threat_category",
                table: "threat",
                column: "category");

            migrationBuilder.CreateIndex(
                name: "IX_threat_framework_id",
                table: "threat",
                column: "framework_id");

            migrationBuilder.CreateIndex(
                name: "IX_threat_framework_id_code",
                table: "threat",
                columns: new[] { "framework_id", "code" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_threat_severity",
                table: "threat",
                column: "severity");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "threat");

            migrationBuilder.DropTable(
                name: "framework");
        }
    }
}
