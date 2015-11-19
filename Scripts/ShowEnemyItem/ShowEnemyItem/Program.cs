using System;
using System.Collections.Generic;
using System.Linq;
using Ensage;
using Ensage.Common;
using Ensage.Common.Menu;
using Ensage.Items;
using SharpDX;

namespace ShowEnemyItem
{
    internal class Program
    {
        private static bool _loaded;
        private static readonly Dictionary<string, DotaTexture> TextureCache = new Dictionary<string, DotaTexture>();
        private static readonly Menu Menu = new Menu("ShowEnemyItems", "ShowEnemyItems", true);

        private static void Main()
        {
            Drawing.OnDraw += Drawing_OnDraw;
            Menu.AddItem(new MenuItem("show", "Show items").SetValue(true));
            Menu.AddItem(new MenuItem("checkforteam", "Only for enemy").SetValue(true));
            Menu.AddItem(new MenuItem("slider", "transparency").SetValue(new Slider(80, 0, 255)));
            Menu.AddItem(new MenuItem("sizer", "Size").SetValue(new Slider(1, 1, 10)));
            Menu.AddItem(new MenuItem("distBetweenSpells", "Distance spells").SetValue(new Slider(0, 0, 200)));
            Menu.AddItem(new MenuItem("DistBwtweenLvls", "Distance lvls").SetValue(new Slider(0, 0, 200)));
            Menu.AddItem(new MenuItem("SizeSpell", "Level size").SetValue(new Slider(0, 1, 25)));

            /*var distBetweenSpells = Menu.Item("distBetweenSpells").GetValue<Slider>().Value;
            var DistBwtweenLvls = Menu.Item("DistBwtweenLvls").GetValue<Slider>().Value;
            var SizeSpell = Menu.Item("SizeSpell").GetValue<Slider>().Value;*/
            Menu.AddToMainMenu();
        }

        private static void Drawing_OnDraw(EventArgs args)
        {
            var me = ObjectMgr.LocalHero;

            if (!_loaded)
            {

                if (!Game.IsInGame || me == null)
                {
                    return;
                }
                _loaded = true;
                PrintSuccess("> ShowEnemyItems loaded!");
                Game.PrintMessage(
                    "<font face='Comic Sans MS, cursive'><font color='#00aaff'>" +
                    "ShowEnemyItems loaded!</font>", MessageType.LogMessage);
            }

            if (!Game.IsInGame || me == null)
            {
                _loaded = false;
                PrintInfo("> ShowEnemyItems unLoaded");
                return;
            }
            if (!Menu.Item("show").GetValue<bool>()) return;
            var percent = HUDInfo.RatioPercentage();
            for (uint i = 0; i < 10; i++)
            {
                #region Init

                Hero v;
                try
                {
                    v = ObjectMgr.GetPlayerById(i).Hero;
                }
                catch
                {
                    continue;
                }
                if (v == null) continue;
                if (!v.IsValid) continue;
                #endregion

                Vector2 pos;
                if ( v.IsVisible && v.IsAlive && Drawing.WorldToScreen(v.Position,out pos))
                {
                    if (Menu.Item("checkforteam").GetValue<bool>())
                    {
                        if (v.Team == me.Team)
                        {
                            continue;
                        }
                    }
                    var invetory = v.Inventory.Items;
                    var iPos = HUDInfo.GetHPbarPosition(v);
                    var iSize = new Vector2(HUDInfo.GetHPBarSizeX(v), HUDInfo.GetHpBarSizeY(v));
                    float yPos = 0;
                    float count = 0;
                    var n = 0;
                    var botrange = iSize.X/4;
                    var coef = Menu.Item("sizer").GetValue<Slider>().Value;
                    Drawing.DrawRect(iPos + new Vector2(0, -iSize.Y - iSize.X/3),
                        new Vector2(iSize.X/2*coef, (float) (iSize.Y*3.5)*coef),
                        GetTexture("materials/ensage_ui/heroes_horizontal/" + v.Name.Replace("npc_dota_hero_", "") +
                                   ".vmat"));
                    #region Items
                    foreach (var item in invetory)
                    {
                        n++;
                        var itemname = string.Format("materials/ensage_ui/items/{0}.vmat",
                            item.Name.Replace("item_", ""));
                        if (item is Bottle)
                        {
                            var bottletype = item as Bottle;
                            if (bottletype.StoredRune != RuneType.None)
                            {
                                itemname = string.Format("materials/ensage_ui/items/{0}.vmat",
                                    item.Name.Replace("item_", "") + "_" + bottletype.StoredRune);
                                //Game.PrintMessage(itemname, MessageType.LogMessage);
                            }
                        }

                        Drawing.DrawRect(iPos + new Vector2(count, botrange + yPos),
                            new Vector2(iSize.X/3*coef, (float) (iSize.Y*2.5)*coef),
                            GetTexture(itemname));

                        if (item.AbilityState == AbilityState.OnCooldown)
                        {
                            Drawing.DrawRect(iPos + new Vector2(count, botrange + yPos),
                                new Vector2((iSize.X/4)*coef,
                                    item.Cooldown/item.CooldownLength*
                                    ((float) (iSize.Y*2.5)*coef)),
                                new Color(255, 255, 255, Menu.Item("slider").GetValue<Slider>().Value));
                        }
                        if (item.AbilityState == AbilityState.NotEnoughMana)
                        {
                            Drawing.DrawRect(iPos + new Vector2(count, botrange + yPos),
                                new Vector2((iSize.X/5)*coef, (float) (iSize.Y*2.5)*coef),
                                new Color(0, 0, 200, Menu.Item("slider").GetValue<Slider>().Value));
                        }
                        count += iSize.X/4*coef;
                        if (n != 3) continue;
                        count = 0;
                        yPos = (int) ((iSize.Y*2.5)*coef);
                    }

                    #endregion

                    #region Spells
                    //Game.PrintMessage(percent.ToString(),MessageType.ChatMessage);
                    var start = new Vector2(iPos.X, iPos.Y + 120 * percent) + new Vector2(0, yPos);

                    
                    var g = -1;
                    var distBetweenSpells = Menu.Item("distBetweenSpells").GetValue<Slider>().Value;
                    var DistBwtweenLvls = Menu.Item("DistBwtweenLvls").GetValue<Slider>().Value;
                    var SizeSpell = Menu.Item("SizeSpell").GetValue<Slider>().Value;
                    var size = distBetweenSpells; //(iSize.X / 3);
                    var sizey = 9;

                    foreach (var spell in v.Spellbook.Spells.Where(x=>x.AbilityType!=AbilityType.Attribute))
                    {
                        g++;
                        var cd = spell.Cooldown;
                        Drawing.DrawRect(start + new Vector2((g * size), 0), new Vector2(size, spell.AbilityState != AbilityState.OnCooldown ? sizey : 22),
                            new ColorBGRA(0, 0, 0, 100));
                        Drawing.DrawRect(start + new Vector2((g * size), 0), new Vector2(size, spell.AbilityState != AbilityState.OnCooldown ? sizey : 22),
                            new ColorBGRA(255, 255, 255, 100), true);
                        if (spell.AbilityState == AbilityState.NotEnoughMana)
                        {
                            Drawing.DrawRect(start + new Vector2((g * size), 0),
                                new Vector2(size, spell.AbilityState != AbilityState.OnCooldown ? sizey : 22),
                                new ColorBGRA(0, 0, 150, 150));
                        }
                        if (spell.AbilityState==AbilityState.OnCooldown)
                        {
                            var text = string.Format("{0:0.#}", cd);
                            var textSize = Drawing.MeasureText(text, "Arial", new Vector2(10, 200),
                                FontFlags.None);
                            var textPos = (start + new Vector2(g * size, 0) +
                                           new Vector2(10 - textSize.X / 2, -textSize.Y / 2 + 12));
                            Drawing.DrawText(text, textPos, /*new Vector2(10, 150),*/ Color.White,
                                FontFlags.AntiAlias | FontFlags.DropShadow);
                        }
                        if (spell.Level == 0) continue;
                        for (var lvl = 1; lvl <= spell.Level; lvl++)
                        {
                            Drawing.DrawRect(start + new Vector2((g * (size) + (/*4+*/DistBwtweenLvls) * lvl), sizey - 6), new Vector2(SizeSpell, sizey-6),
                                new ColorBGRA(255, 255, 0, 255));
                        }

                    }

                    #endregion

                }
            }
        }
        #region Helpers

        private static DotaTexture GetTexture(string name)
        {
            if (TextureCache.ContainsKey(name)) return TextureCache[name];

            return TextureCache[name] = Drawing.GetTexture(name);
        }

        private static void PrintInfo(string text, params object[] arguments)
        {
            PrintEncolored(text, ConsoleColor.White, arguments);
        }

        private static void PrintSuccess(string text, params object[] arguments)
        {
            PrintEncolored(text, ConsoleColor.Green, arguments);
        }

        // ReSharper disable once UnusedMember.Local
        private static void PrintError(string text, params object[] arguments)
        {
            PrintEncolored(text, ConsoleColor.Red, arguments);
        }

        private static void PrintEncolored(string text, ConsoleColor color, params object[] arguments)
        {
            var clr = Console.ForegroundColor;
            Console.ForegroundColor = color;
            Console.WriteLine(text, arguments);
            Console.ForegroundColor = clr;
        }

        #endregion
    }
}


